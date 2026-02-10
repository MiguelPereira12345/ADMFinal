import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../app/session_scope.dart';
import '../widgets/app/app_scaffold.dart';
import '../widgets/app/app_error_view.dart';
import '../widgets/patients/dependents_card.dart';
import '../widgets/patients/empty_card.dart';
import '../utils/app_formatters.dart';
import 'dependent_profile_page.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  Future<Map<String, dynamic>>? _future;
  bool _handledAuthError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final session = SessionScope.of(context);
    final patientId = session.patientId;
    if (patientId == null) {
      throw Exception('Sessão inválida. Faça login novamente.');
    }
    final json = await session.patientApi.listDependents(patientId);
    return json;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Dependentes',
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _future = _load();
          });
          await _future;
        },
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final err = snapshot.error;
              final status = (err is ApiException) ? err.status : null;
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
                return const Center(child: CircularProgressIndicator());
              }

              return AppErrorView(
                error: snapshot.error,
                onRetry: () => setState(() {
                  _handledAuthError = false;
                  _future = _load();
                }),
              );
            }

            final json = snapshot.data ?? <String, dynamic>{};
            final list = _extractList(json);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                const Text(
                  'Os seus dependentes associados',
                  style: TextStyle(color: Colors.black54),
                ),
                if (list.isEmpty)
                  const EmptyCard(text: 'Sem dependentes.')
                else
                  DependentsCard(
                    items: list,
                    onView: (item) => _openDependentProfile(item),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openDependentProfile(Map<String, dynamic> item) {
    final id = _dependentId(item);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir: ID do dependente em falta.'),
        ),
      );
      return;
    }

    final nome = firstString(item, ['nome', 'name', 'paciente_nome']);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DependentProfilePage(
          dependentId: id,
          dependentName: nome,
          initialItem: item,
        ),
      ),
    );
  }

  static List<Map<String, dynamic>> _extractList(Map<String, dynamic> json) {
    List<Map<String, dynamic>> asMapList(Object? v) {
      if (v is List) {
        return v
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
      if (v is Map) {
        final m = v.cast<String, dynamic>();
        // common nested shapes: { items: [...] } or { data: [...] }
        for (final k in const ['dependents', 'dependentes', 'items', 'data']) {
          final nested = m[k];
          if (nested is List) {
            return nested
                .whereType<Map>()
                .map((e) => e.cast<String, dynamic>())
                .toList();
          }
        }
      }
      return const <Map<String, dynamic>>[];
    }

    for (final k in const [
      'dependents',
      'dependentes',
      'data',
      'items',
      'result',
      'results',
    ]) {
      final out = asMapList(json[k]);
      if (out.isNotEmpty) return out;
    }

    // Fallback: scan first-level values for a list.
    for (final v in json.values) {
      final out = asMapList(v);
      if (out.isNotEmpty) return out;
    }

    return const <Map<String, dynamic>>[];
  }
}

int? _dependentId(Map<String, dynamic> item) {
  final direct = _asInt(
    item['id'] ??
        item['dependent_id'] ??
        item['dependente_id'] ??
        item['id_dependente'] ??
        item['idDependente'] ??
        item['dependentId'] ??
        item['dependenteId'] ??
        item['patient_id'] ??
        item['id_paciente'] ??
        item['idPaciente'],
  );
  if (direct != null) return direct;

  final nested = (item['dependent'] is Map)
      ? (item['dependent'] as Map).cast<String, dynamic>()
      : (item['dependente'] is Map)
      ? (item['dependente'] as Map).cast<String, dynamic>()
      : null;
  if (nested == null) return null;

  return _asInt(
    nested['id'] ??
        nested['dependent_id'] ??
        nested['dependente_id'] ??
        nested['id_dependente'] ??
        nested['idDependente'] ??
        nested['dependentId'] ??
        nested['dependenteId'] ??
        nested['patient_id'] ??
        nested['id_paciente'] ??
        nested['idPaciente'],
  );
}

int? _asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '');
}
