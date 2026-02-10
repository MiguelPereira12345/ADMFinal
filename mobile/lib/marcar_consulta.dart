import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'widgets/app/app_error_view.dart';
import 'widgets/app_bottom_nav.dart';
import 'app/session_scope.dart';

import 'pages/request_consulta_page.dart';
import 'pages/consulta_details_page.dart';

class MarcarConsulta extends StatefulWidget {
  const MarcarConsulta({super.key});

  @override
  State<MarcarConsulta> createState() => _MarcarConsultaState();
}

class _MarcarConsultaState extends State<MarcarConsulta> {
  Future<Map<String, dynamic>>? _future;
  String _futureQuery = '';
  String _pastQuery = '';

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFFAF7F4);
    const int currentIndex = 1;
    final primaryGold = const Color(0xFFA87B05);

    _future ??= _load();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return AppErrorView(
                  error: snapshot.error,
                  onRetry: () => setState(() {
                    _future = _load();
                  }),
                );
              }

              final json = snapshot.data ?? <String, dynamic>{};
              final consultas = _extractList(json);

              final now = DateTime.now();
              final futuras = <Map<String, dynamic>>[];
              final passadas = <Map<String, dynamic>>[];

              for (final c in consultas) {
                final status = (c['status'] ?? c['estado'] ?? '')
                    .toString()
                    .trim();
                final dt = _consultaDateTime(c);
                final isCancelled = _isCancelledStatus(status);
                final isPast = isCancelled || (dt != null && dt.isBefore(now));
                (isPast ? passadas : futuras).add(c);
              }

              futuras.sort((a, b) {
                final da = _consultaDateTime(a);
                final db = _consultaDateTime(b);
                if (da == null && db == null) return 0;
                if (da == null) return 1;
                if (db == null) return -1;
                return da.compareTo(db);
              });

              passadas.sort((a, b) {
                final da = _consultaDateTime(a);
                final db = _consultaDateTime(b);
                if (da == null && db == null) return 0;
                if (da == null) return 1;
                if (db == null) return -1;
                return db.compareTo(da);
              });

              Future<void> refresh() async {
                setState(() {
                  _future = _load();
                });
                await _future;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Consultas',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Veja as consultas futuras e o histórico de consultas.',
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGold,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _requestConsulta,
                            child: const Text('Marcar Consulta'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.black12, width: 1),
                            ),
                          ),
                          child: TabBar(
                            labelColor: primaryGold,
                            unselectedLabelColor: Colors.black54,
                            indicatorColor: primaryGold,
                            indicatorWeight: 3,
                            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                            tabs: const [
                              Tab(text: 'Futuras'),
                              Tab(text: 'Passadas'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ConsultasListTab(
                          hintText: 'Pesquisar consultas futuras…',
                          query: _futureQuery,
                          onQueryChanged: (v) =>
                              setState(() => _futureQuery = v),
                          consultas: _filterConsultas(futuras, _futureQuery),
                          onRefresh: refresh,
                          onOpen: _openConsulta,
                          emptyText: 'Sem consultas futuras.',
                        ),
                        _ConsultasListTab(
                          hintText: 'Pesquisar consultas passadas…',
                          query: _pastQuery,
                          onQueryChanged: (v) => setState(() => _pastQuery = v),
                          consultas: _filterConsultas(passadas, _pastQuery),
                          onRefresh: refresh,
                          onOpen: _openConsulta,
                          emptyText: 'Sem consultas passadas.',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: AppBottomNav(selectedIndex: currentIndex),
      ),
    );
  }

  Future<Map<String, dynamic>> _load() async {
    final session = SessionScope.of(context);
    final patientId = session.patientId;
    if (patientId == null) throw Exception('Sessão inválida.');
    return session.patientApi.listConsultas(patientId);
  }

  Future<void> _openConsulta(Map<String, dynamic> consulta) async {
    final session = SessionScope.of(context);
    final userId = session.patientId;
    final id = _consultaId(consulta);
    if (userId == null || id == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ConsultaDetailsPage(consultaId: id, initialConsulta: consulta),
      ),
    );
  }

  Future<void> _requestConsulta() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) {
        final height = MediaQuery.of(ctx).size.height;
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFAF7F4),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: height * 0.95),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      Expanded(
                        child: RequestConsultaPage(
                          embedded: true,
                          scrollController: scrollController,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (!mounted) return;
    if (created == true) {
      setState(() => _future = _load());
    }
  }

  static List<Map<String, dynamic>> _extractList(Map<String, dynamic> json) {
    final candidates = [json['consultas'], json['data'], json['items']];
    for (final c in candidates) {
      if (c is List) {
        return c
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
    }
    return const [];
  }

  static List<Map<String, dynamic>> _filterConsultas(
    List<Map<String, dynamic>> items,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((c) {
      final hay = [
        c['status'],
        c['estado'],
        c['medico_nome'],
        c['doctor_name'],
        c['especialidade'],
        c['especialidade_nome'],
        c['dependente_nome'],
        c['dependent_name'],
        c['data_consulta'],
        c['data'],
        c['date'],
        c['hora'],
        c['time'],
        c['id'],
        c['id_consulta'],
      ].where((v) => v != null).map((v) => v.toString()).join(' ');
      return hay.toLowerCase().contains(q);
    }).toList();
  }
}

class _ConsultasListTab extends StatelessWidget {
  final String hintText;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final List<Map<String, dynamic>> consultas;
  final Future<void> Function() onRefresh;
  final void Function(Map<String, dynamic>) onOpen;
  final String emptyText;

  const _ConsultasListTab({
    required this.hintText,
    required this.query,
    required this.onQueryChanged,
    required this.consultas,
    required this.onRefresh,
    required this.onOpen,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: hintText,
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: query.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar',
                      onPressed: () => onQueryChanged(''),
                      icon: const Icon(Icons.close),
                    ),
            ),
            onChanged: onQueryChanged,
          ),
          const SizedBox(height: 12),
          if (consultas.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  emptyText,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ...consultas.map(
              (c) => _ConsultaCard(consulta: c, onTap: () => onOpen(c)),
            ),
        ],
      ),
    );
  }
}

int? _asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '');
}

int? _consultaId(Map<String, dynamic> item) {
  final direct = _asInt(
    item['id_consulta'] ??
        item['consulta_id'] ??
        item['idConsulta'] ??
        item['consultaId'] ??
        item['id'] ??
        item['consultaID'] ??
        item['id_consulta_marcacao'],
  );
  if (direct != null) return direct;

  final nested = (item['consulta'] is Map)
      ? (item['consulta'] as Map).cast<String, dynamic>()
      : null;
  if (nested == null) return null;

  return _asInt(
    nested['id_consulta'] ??
        nested['consulta_id'] ??
        nested['idConsulta'] ??
        nested['consultaId'] ??
        nested['id'] ??
        nested['consultaID'] ??
        nested['id_consulta_marcacao'],
  );
}

class _ConsultaCard extends StatelessWidget {
  final Map<String, dynamic> consulta;
  final VoidCallback onTap;

  const _ConsultaCard({required this.consulta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final id = _asInt(consulta['id'] ?? consulta['id_consulta']);
    final status = (consulta['status'] ?? consulta['estado'] ?? '')
        .toString()
        .trim();
    final dateTimeLine = _formatDateTimeLine(consulta);

    final medico =
        (consulta['medico_nome'] ??
                consulta['doctor_name'] ??
                consulta['id_medico'])
            ?.toString()
            .trim();
    final profissional = (medico == null || medico.isEmpty) ? '—' : medico;

    final dependente =
        (consulta['dependente_nome'] ?? consulta['dependent_name'])
            ?.toString()
            .trim();

    final chip = _statusChip(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.06),
                  blurRadius: 12,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Consulta #${id ?? '?'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          _StatusChipWidget(text: chip.text, color: chip.color),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dateTimeLine,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Profissional: $profissional',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      if (dependente != null && dependente.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Para: $dependente',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.chevron_right, color: Colors.black45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip {
  final String text;
  final Color color;
  const _StatusChip(this.text, this.color);
}

class _StatusChipWidget extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusChipWidget({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final bg = color.withValues(alpha: 0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        text.isEmpty ? '—' : text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

_StatusChip _statusChip(String statusRaw) {
  final s = statusRaw.trim();
  if (s.isEmpty) return const _StatusChip('—', Colors.grey);
  final lower = s.toLowerCase();

  if (lower.contains('confirm')) {
    return const _StatusChip('Confirmado', Color(0xFF16A34A));
  }
  if (lower.contains('pend')) {
    return const _StatusChip('Pendente', Color(0xFFF59E0B));
  }
  if (lower.contains('cancel') ||
      lower.contains('rejeit') ||
      lower.contains('recus')) {
    return const _StatusChip('Cancelado', Color(0xFFEF4444));
  }
  return _StatusChip(s, Colors.grey);
}

String _formatDateTimeLine(Map<String, dynamic> consulta) {
  final rawDate =
      (consulta['data_consulta'] ??
              consulta['data'] ??
              consulta['dataHora'] ??
              consulta['datetime'] ??
              consulta['date'])
          ?.toString()
          .trim();

  final rawHour = (consulta['hora'] ?? consulta['time'])?.toString().trim();

  DateTime? dt;
  if (rawDate != null && rawDate.isNotEmpty) {
    dt =
        DateTime.tryParse(rawDate) ??
        DateTime.tryParse(rawDate.replaceFirst(' ', 'T'));
  }

  final dateStr = (dt != null)
      ? DateFormat('dd/MM/yyyy').format(dt)
      : (rawDate?.isNotEmpty == true ? rawDate! : '—');

  String hourStr;
  if (rawHour != null && rawHour.isNotEmpty) {
    hourStr = rawHour;
  } else if (dt != null) {
    hourStr = DateFormat('HH:mm').format(dt);
  } else {
    hourStr = '—';
  }

  if (RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(hourStr)) {
    hourStr = hourStr.substring(0, 5);
  }

  return '$dateStr • $hourStr';
}

bool _isCancelledStatus(String statusRaw) {
  final s = statusRaw.trim().toLowerCase();
  if (s.isEmpty) return false;
  return s.contains('cancel') ||
      s.contains('rejeit') ||
      s.contains('recus') ||
      s.contains('anulad');
}

DateTime? _consultaDateTime(Map<String, dynamic> consulta) {
  final rawDate =
      (consulta['data_consulta'] ??
              consulta['data'] ??
              consulta['dataHora'] ??
              consulta['datetime'] ??
              consulta['date'])
          ?.toString()
          .trim();

  final rawHour = (consulta['hora'] ?? consulta['time'])?.toString().trim();

  DateTime? dt;
  if (rawDate != null && rawDate.isNotEmpty) {
    dt =
        DateTime.tryParse(rawDate) ??
        DateTime.tryParse(rawDate.replaceFirst(' ', 'T'));
  }

  if (dt == null) return null;

  if (rawHour != null && rawHour.isNotEmpty) {
    final hhmm = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$');
    final m = hhmm.firstMatch(rawHour);
    if (m != null) {
      final h = int.tryParse(m.group(1) ?? '');
      final min = int.tryParse(m.group(2) ?? '');
      if (h != null && min != null) {
        dt = DateTime(dt.year, dt.month, dt.day, h, min);
      }
    }
  }

  return dt;
}
