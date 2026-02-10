import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api.dart';
import 'app_notification.dart';

class SessionController extends ChangeNotifier {
  final SharedPreferences _prefs;
  final TokenStore tokenStore;
  final ApiClient apiClient;
  final AuthApi authApi;
  final PatientApi patientApi;

  ApiUser? _user;
  bool _restoring = true;

  List<AppNotification> _notifications = const <AppNotification>[];
  bool _notificationsLoaded = false;

  SessionController._({
    required SharedPreferences prefs,
    required this.tokenStore,
    required this.apiClient,
    required this.authApi,
    required this.patientApi,
  }) : _prefs = prefs;

  static const _userJsonKey = 'auth_user_json';
  static const _notificationsKeyPrefix = 'in_app_notifications_v1_';

  static Future<SessionController> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenStore = SharedPreferencesTokenStore(prefs);

    // Prefer using .env variable if available, otherwise fallback to ApiConfig
    String? envUrl;
    try {
      envUrl = dotenv.env['API_BASE_URL'];
    } catch (_) {
      // dotenv might not be initialized if loading failed
    }

    final baseUrl = (envUrl != null && envUrl.isNotEmpty)
        ? envUrl
        : ApiConfig.defaultBaseUrl;

    final apiClient = ApiClient(
      baseUrl: baseUrl,
      tokenStore: tokenStore,
    );

    final controller = SessionController._(
      prefs: prefs,
      tokenStore: tokenStore,
      apiClient: apiClient,
      authApi: AuthApi(apiClient),
      patientApi: PatientApi(apiClient),
    );

    await controller.restore();
    return controller;
  }

  bool get isRestoring => _restoring;
  ApiUser? get user => _user;
  int? get userId => _user?.id;
  int? get patientId => _user?.patientId ?? _user?.id;
  bool get isLoggedIn => _user != null;

  List<AppNotification> get notifications => _notifications;

  int get unreadNotificationCount =>
      _notifications.where((n) => !n.read).length;

  String? _notificationsKeyForCurrentUser() {
    final id = userId;
    if (id == null) return null;
    return '$_notificationsKeyPrefix$id';
  }

  Future<void> _loadNotificationsForCurrentUser() async {
    final key = _notificationsKeyForCurrentUser();
    if (key == null) {
      _notifications = const <AppNotification>[];
      _notificationsLoaded = true;
      return;
    }
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      _notifications = const <AppNotification>[];
    } else {
      final decoded = AppNotification.decodeList(raw);
      // Sort newest first
      final sorted = decoded.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _notifications = sorted;
    }
    _notificationsLoaded = true;
  }

  Future<void> _persistNotificationsForCurrentUser() async {
    final key = _notificationsKeyForCurrentUser();
    if (key == null) return;
    await _prefs.setString(key, AppNotification.encodeList(_notifications));
  }

  Future<void> addNotification({
    required String title,
    required String body,
    DateTime? createdAt,
  }) async {
    // If notifications haven't been loaded yet, try to load first so we don't overwrite.
    if (!_notificationsLoaded) {
      await _loadNotificationsForCurrentUser();
    }
    final now = createdAt ?? DateTime.now();
    final id = '${now.microsecondsSinceEpoch}';
    final next = <AppNotification>[
      AppNotification(
        id: id,
        title: title,
        body: body,
        createdAt: now,
        read: false,
      ),
      ..._notifications,
    ];
    _notifications = next;
    await _persistNotificationsForCurrentUser();
    notifyListeners();
  }

  Future<void> markNotificationRead(String id) async {
    if (_notifications.isEmpty) return;
    var changed = false;
    final next = _notifications.map((n) {
      if (n.id == id && !n.read) {
        changed = true;
        return n.copyWith(read: true);
      }
      return n;
    }).toList();
    if (!changed) return;
    _notifications = next;
    await _persistNotificationsForCurrentUser();
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    if (_notifications.isEmpty) return;
    if (unreadNotificationCount == 0) return;
    _notifications = _notifications.map((n) => n.read ? n : n.copyWith(read: true)).toList();
    await _persistNotificationsForCurrentUser();
    notifyListeners();
  }

  Future<void> clearNotifications() async {
    if (_notifications.isEmpty) return;
    _notifications = const <AppNotification>[];
    await _persistNotificationsForCurrentUser();
    notifyListeners();
  }

  Future<void> restore() async {
    _restoring = true;
    notifyListeners();

    // 1) Quick restore from prefs (for immediate UI), if present.
    final cachedUser = _prefs.getString(_userJsonKey);
    if (cachedUser != null && cachedUser.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedUser);
        if (decoded is Map) {
          _user = ApiUser.fromJson(decoded.cast<String, dynamic>());
        }
      } catch (_) {
        // ignore cache parsing errors
      }
    }

    // 2) Validate token by calling /auth/me if we have an access token.
    try {
      final tokens = await tokenStore.read();
      if (tokens?.accessToken != null && tokens!.accessToken.isNotEmpty) {
        final me = await authApi.me();
        _user = me;
        await _prefs.setString(_userJsonKey, jsonEncode({
          'id': me.id,
          if (me.patientId != null) 'patientId': me.patientId,
          'nome': me.nome,
          'email': me.email,
          'tipo': me.tipo,
        }));

        await _loadNotificationsForCurrentUser();
      } else {
        _user = null;
        _notifications = const <AppNotification>[];
        _notificationsLoaded = true;
      }
    } catch (_) {
      // Token inválido/expirado ou backend offline.
      await tokenStore.clear();
      _user = null;
      _notifications = const <AppNotification>[];
      _notificationsLoaded = true;
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }

  Future<LoginResult> loginPaciente({required String email, required String senha}) async {
    final result = await authApi.loginPaciente(email: email, senha: senha);
    _user = result.user;
    await _prefs.setString(_userJsonKey, jsonEncode({
      'id': result.user.id,
      if (result.user.patientId != null) 'patientId': result.user.patientId,
      'nome': result.user.nome,
      'email': result.user.email,
      'tipo': result.user.tipo,
    }));

    await _loadNotificationsForCurrentUser();
    notifyListeners();
    return result;
  }

  Future<void> logout() async {
    try {
      await authApi.logout();
    } catch (_) {
      // ignore network errors on logout
      await tokenStore.clear();
    }
    _user = null;
    await _prefs.remove(_userJsonKey);

    _notifications = const <AppNotification>[];
    _notificationsLoaded = false;
    notifyListeners();
  }
}
