import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../app/session_scope.dart';
import '../widgets/app/app_error_view.dart';
import '../widgets/consultas/consulta_details_body.dart';

class ConsultaDetailsPage extends StatefulWidget {
  final int consultaId;
  final Map<String, dynamic>? initialConsulta;

  const ConsultaDetailsPage({
    super.key,
    required this.consultaId,
    this.initialConsulta,
  });

  @override
  State<ConsultaDetailsPage> createState() => _ConsultaDetailsPageState();
}

class _ConsultaDetailsPageState extends State<ConsultaDetailsPage> {
  Future<Map<String, dynamic>>? _future;
  bool _handledAuthError = false;

  @override
  void initState() {
    super.initState();
    // Needs context from SessionScope; delay until first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _future ??= _load();
      });
    });
  }

  Future<Map<String, dynamic>> _load() async {
    final session = SessionScope.of(context);
    final patientId = session.patientId;
    if (patientId == null) throw Exception('Sessão inválida.');

    final json = await session.patientApi.getConsulta(patientId, widget.consultaId);
    final consulta = (json['consulta'] is Map)
        ? (json['consulta'] as Map).cast<String, dynamic>()
        : json;
    return consulta;
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFFAF7F4);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Detalhes da Consulta'),
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              final err = snapshot.error;
              final status = (err is ApiException) ? err.status : null;

              if (status == 404 && widget.initialConsulta != null) {
                final consulta = widget.initialConsulta!;
                return ConsultaDetailsBody(
                  consulta: consulta,
                  showFallbackNote: true,
                );
              }

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

              final message = switch (status) {
                404 => 'Consulta não encontrada.',
                _ => 'Não foi possível carregar a consulta.',
              };

              return AppErrorView(
                error: "$message${err != null ? '\n$err' : ''}",
                onRetry: () => setState(() => _future = _load()),
              );
            }

            final consulta = snapshot.data ?? <String, dynamic>{};
            return ConsultaDetailsBody(consulta: consulta);
          },
        ),
      ),
    );
  }
}

