import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/api_client.dart';
import '../app/session_scope.dart';
import '../widgets/app/app_scaffold.dart';
import '../widgets/app/app_card.dart';
import '../widgets/app/app_info_row.dart';
import '../widgets/app/app_section_title.dart';

class DependentProfilePage extends StatefulWidget {
  final int dependentId;
  final String? dependentName;
  final Map<String, dynamic> initialItem;

  const DependentProfilePage({
    super.key,
    required this.dependentId,
    required this.initialItem,
    this.dependentName,
  });

  @override
  State<DependentProfilePage> createState() => _DependentProfilePageState();
}

class _DependentProfilePageState extends State<DependentProfilePage> {
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
    if (patientId == null) throw Exception('Sessão inválida.');

    try {
      final json = await session.patientApi.getDependent(
        patientId,
        widget.dependentId,
      );
      final data = (json['dependent'] is Map)
          ? (json['dependent'] as Map).cast<String, dynamic>()
          : (json['dependente'] is Map)
          ? (json['dependente'] as Map).cast<String, dynamic>()
          : json;
      return data;
    } catch (e) {
      final status = (e is ApiException) ? e.status : null;
      if (status == 404) {
        // Fallback: still render a page using the list payload.
        return widget.initialItem;
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.dependentName ?? 'Dependente',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    final err = snapshot.error;
                    final status = (err is ApiException) ? err.status : null;
                    if ((status == 401 || status == 403) &&
                        !_handledAuthError) {
                      _handledAuthError = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final session = SessionScope.of(context);
                        final navigator = Navigator.of(context);
                        session.logout().then((_) {
                          if (!mounted) return;
                          navigator.pushNamedAndRemoveUntil(
                            '/login',
                            (r) => false,
                          );
                        });
                      });
                      return const Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    return _ErrorCard(
                      message: 'Não foi possível carregar o dependente.',
                      details: err?.toString(),
                      onRetry: () {
                        setState(() {
                          _handledAuthError = false;
                          _future = _load();
                        });
                      },
                    );
                  }

                  final dep = snapshot.data ?? <String, dynamic>{};

                  final nome =
                      _firstString(dep, ['nome', 'name']) ??
                      widget.dependentName;
                  final email = _firstString(dep, ['email']);
                  final telefone = _firstString(dep, ['telefone', 'phone']);
                  final sexo = _firstString(dep, ['sexo', 'gender']);
                  final endereco = _firstString(dep, ['endereco', 'address']);
                  final nif = _firstString(dep, ['nif']);
                  final numeroUtente = _firstString(dep, [
                    'numero_utente',
                    'numeroUtente',
                  ]);
                  final dataNascimento = _formatDate(
                    _firstString(dep, [
                      'data_nascimento',
                      'dataNascimento',
                      'birth_date',
                      'dob',
                    ]),
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppSectionTitle('Informações pessoais'),
                      const SizedBox(height: 10),
                      AppCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            AppInfoRow(label: 'Nome', value: _display(nome)),
                            const Divider(height: 16),
                            AppInfoRow(label: 'Email', value: _display(email)),
                            const Divider(height: 16),
                            AppInfoRow(label: 'Telefone', value: _display(telefone)),
                            const Divider(height: 16),
                            AppInfoRow(label: 'Sexo', value: _display(sexo)),
                            const Divider(height: 16),
                            AppInfoRow(label: 'Endereço', value: _display(endereco)),
                            const Divider(height: 16),
                            AppInfoRow(label: 'Data nascimento', value: _display(dataNascimento)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const AppSectionTitle('Documentos'),
                      const SizedBox(height: 10),
                      AppCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            AppInfoRow(label: 'NIF', value: _display(nif)),
                            const Divider(height: 16),
                            AppInfoRow(label: 'Nº utente', value: _display(numeroUtente)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.details,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.red.shade700,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (details != null && details!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            details!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: OutlinedButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ),
      ],
    );
  }
}

String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final v = json[key];
    if (v == null) continue;
    final s = v.toString();
    if (s.isNotEmpty) return s;
  }
  return null;
}

String _display(String? value) {
  final v = value?.trim();
  return (v == null || v.isEmpty) ? '—' : v;
}

String? _formatDate(String? raw) {
  final v = raw?.trim();
  if (v == null || v.isEmpty) return null;
  final parsed = DateTime.tryParse(v);
  if (parsed == null) return v;
  return DateFormat('dd/MM/yyyy').format(parsed);
}
