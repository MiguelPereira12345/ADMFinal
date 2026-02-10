import 'dart:convert';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? read,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'read': read,
    };
  }

  static AppNotification fromJson(Map<String, dynamic> json) {
    final createdRaw = json['createdAt'];
    DateTime createdAt;
    if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return AppNotification(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      createdAt: createdAt,
      read: json['read'] == true,
    );
  }

  static List<AppNotification> decodeList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((m) => AppNotification.fromJson(m.cast<String, dynamic>()))
            .toList();
      }
    } catch (_) {
      // ignore
    }
    return const <AppNotification>[];
  }

  static String encodeList(List<AppNotification> items) {
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }
}
