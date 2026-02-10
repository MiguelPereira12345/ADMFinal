import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../api/api_client.dart';
import '../api/files_api.dart';
import '../api/models.dart';
import '../app/session_scope.dart';
import '../widgets/app/app_colors.dart';

class DeclarationsDocsPage extends StatefulWidget {
  const DeclarationsDocsPage({super.key});

  @override
  State<DeclarationsDocsPage> createState() => _DeclarationsDocsPageState();
}

class _DeclarationsDocsPageState extends State<DeclarationsDocsPage> {
  bool _initialized = false;
  bool _handledAuthError = false;

  bool _loadingDocs = false;
  Object? _docsError;
  List<ApiFileItem> _docs = const [];
  String _docsQuery = '';
  int? _downloadingDocId;

  late FilesApi _filesApi;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final session = SessionScope.of(context);
    _filesApi = FilesApi(session.apiClient);
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await _loadDocs();
  }

  Future<void> _loadDocs() async {
    final session = SessionScope.of(context);
    final patientId = session.patientId;
    if (patientId == null) {
      setState(() {
        _docsError = Exception('Sessão inválida.');
      });
      return;
    }

    setState(() {
      _loadingDocs = true;
      _docsError = null;
    });

    try {
      final items = await _filesApi.listFiles(patientId: patientId);
      if (!mounted) return;
      setState(() {
        _docs = items;
      });
    } catch (e) {
      if (!mounted) return;
      _handleAuthIfNeeded(e);
      setState(() {
        _docsError = e;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingDocs = false;
        });
      }
    }
  }

  void _handleAuthIfNeeded(Object e) {
    final status = (e is ApiException) ? e.status : null;
    if ((status == 401 || status == 403) && !_handledAuthError) {
      _handledAuthError = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final session = SessionScope.of(context);
        final navigator = Navigator.of(context);
        session.logout().then((_) {
          if (!mounted) return;
          navigator.pushNamedAndRemoveUntil('/login', (r) => false);
        });
      });
    }
  }

  List<ApiFileItem> get _filteredDocs {
    final q = _docsQuery.trim().toLowerCase();
    if (q.isEmpty) return _docs;
    return _docs.where((d) {
      final hay = [
        d.name,
        d.mimeType,
        d.category,
      ].whereType<String>().join(' ');
      return hay.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.bg;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Declarações/Docs',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _DocsTab(
        backgroundColor: bg,
        loading: _loadingDocs,
        error: _docsError,
        items: _filteredDocs,
        query: _docsQuery,
        onQueryChanged: (v) => setState(() => _docsQuery = v),
        onRefresh: _loadDocs,
        downloadingId: _downloadingDocId,
        onDownload: _downloadDoc,
      ),
    );
  }

  Future<void> _downloadDoc(ApiFileItem doc) async {
    setState(() => _downloadingDocId = doc.id);
    try {
      final res = await _filesApi.downloadFile(doc.id);
      await _saveAndOpen(bytes: res.bytes, filename: res.filename ?? doc.name);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Documento descarregado.')));
    } catch (e) {
      if (!mounted) return;
      _handleAuthIfNeeded(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _friendlyError(e, fallback: 'Erro ao descarregar documento.'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _downloadingDocId = null);
      }
    }
  }

  static String _friendlyError(Object e, {required String fallback}) {
    if (e is ApiException) {
      final msg = e.message.trim();
      return msg.isEmpty ? fallback : msg;
    }
    return fallback;
  }

  static Future<void> _saveAndOpen({
    required List<int> bytes,
    required String filename,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeName = _sanitizeFilename(filename);
    final file = File('${dir.path}${Platform.pathSeparator}$safeName');
    await file.writeAsBytes(bytes, flush: true);
    await OpenFilex.open(file.path);
  }

  static String _sanitizeFilename(String input) {
    var name = input.trim();
    if (name.isEmpty) return 'download.pdf';

    // Windows-illegal characters + control chars
    name = name.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_');
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (name.isEmpty) return 'download.pdf';
    if (name.length > 160) {
      name = name.substring(name.length - 160);
    }
    return name;
  }
}

class _DocsTab extends StatelessWidget {
  final Color backgroundColor;
  final bool loading;
  final Object? error;
  final List<ApiFileItem> items;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final Future<void> Function() onRefresh;
  final int? downloadingId;
  final void Function(ApiFileItem) onDownload;

  const _DocsTab({
    required this.backgroundColor,
    required this.loading,
    required this.error,
    required this.items,
    required this.query,
    required this.onQueryChanged,
    required this.onRefresh,
    required this.downloadingId,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGold),
      );
    }

    if (error != null && items.isEmpty) {
      return _ErrorState(
        message: 'Não foi possível carregar os documentos.',
        details: error.toString(),
        onRetry: onRefresh,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primaryGold,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          _SearchCard(
            hintText: 'Pesquisar documentos…',
            onChanged: onQueryChanged,
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'Sem documentos para mostrar.',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...items.map((doc) {
              final downloading = downloadingId == doc.id;
              return _AppCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.beige,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: AppColors.primaryGold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _docSubtitle(doc),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: downloading ? null : () => onDownload(doc),
                        icon: downloading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Descarregar/Abrir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  static String _docSubtitle(ApiFileItem doc) {
    final parts = <String>[];
    final date = doc.createdAt;
    if (date != null) {
      parts.add(
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
      );
    }
    if (doc.category != null && doc.category!.trim().isNotEmpty) {
      parts.insert(0, doc.category!.trim());
    }
    return parts.isEmpty ? 'Documento' : parts.join(' • ');
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String details;
  final Future<void> Function() onRetry;

  const _ErrorState({
    required this.message,
    required this.details,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              details,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;

  const _AppCard({required this.child, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.03),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SearchCard extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;

  const _SearchCard({required this.hintText, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
