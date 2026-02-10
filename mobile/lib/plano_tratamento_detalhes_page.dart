import 'package:flutter/material.dart';
import 'app/session_scope.dart';
import 'treatment_plans/models.dart';

class PlanoTratamentoDetalhesPage extends StatefulWidget {
  final Map<String, dynamic> plan;

  const PlanoTratamentoDetalhesPage({super.key, required this.plan});

  @override
  State<PlanoTratamentoDetalhesPage> createState() =>
      _PlanoTratamentoDetalhesPageState();
}

class _PlanoTratamentoDetalhesPageState
    extends State<PlanoTratamentoDetalhesPage> {
  Future<PlanSummary>? _detailsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _detailsFuture ??= _loadDetails();
  }

  Future<PlanSummary> _loadDetails() async {
    final session = SessionScope.of(context);
    final userId = session.userId;
    final plan = widget.plan;
    
    // Prioridade correta: id_tratamento > planoId > id (evita usar o ID do paciente 'id')
    final id = _asInt(plan['id_tratamento'] ?? plan['planoId'] ?? plan['id']);
    
    if (userId == null || id == null) throw Exception('Dados inválidos');
    final map = await session.patientApi.getPlano(userId, id);

    // O backend retorna estrutura { "plano": {...}, "consultas": [...] }
    // Precisamos juntar tudo num único mapa para o PlanSummary processar
    Map<String, dynamic> combinedData;
    if (map.containsKey('plano') && map['plano'] is Map) {
      combinedData = Map<String, dynamic>.from(map['plano'] as Map);
    } else {
      combinedData = Map<String, dynamic>.from(map);
    }

    // Se as consultas estiverem na raiz, injetamo-las no objeto do plano
    if (map.containsKey('consultas')) {
      combinedData['consultas'] = map['consultas'];
    }
    
    return PlanSummary.fromJson(combinedData);
  }

  static int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EDE7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3EDE7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Detalhes do tratamento',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<PlanSummary>(
          future: _detailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Erro ao carregar detalhes:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _detailsFuture = _loadDetails();
                          });
                        },
                        child: const Text('Tentar Novamente'),
                      )
                    ],
                  ),
                ),
              );
            }

            final plan = snapshot.data ?? PlanSummary.fromJson(widget.plan);
            final session = SessionScope.of(context);
            final userParams = session.user;
            final pacienteName = userParams?.nome ?? 'Utente';

            final title = plan.nome ?? 'Plano';
            final status = plan.status; 
            final description = plan.descricao ?? '--';
            final startDate = formatDatePt(plan.dataInicio);
            final endDate = formatDatePt(plan.dataFim);
            final consultas = plan.consultas;

            // Lógica de cores do status
            final isPending = status.toLowerCase().contains('pen');
            final isConfirmed = status.toLowerCase().contains('con') ||
                status.toLowerCase().contains('ati');

            final statusBg = isPending
                ? const Color(0xFFFFF8E1)
                : (isConfirmed ? const Color(0xFFE8F5E9) : Colors.grey.shade50);
            final statusText = isPending
                ? const Color(0xFFF57C00)
                : (isConfirmed ? const Color(0xFF2E7D32) : Colors.grey.shade700);
            final statusBorder = isPending
                ? const Color(0xFFFFE0B2)
                : (isConfirmed ? const Color(0xFFA5D6A7) : Colors.grey.shade200);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card 1: Detalhes
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10), // 0.04 * 255
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Detalhes',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Informação principal',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusBorder),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusText,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      _DetailRow(label: 'Para', value: pacienteName, isBold: true),
                      _DetailRow(label: 'Início', value: startDate, isBold: true),
                      _DetailRow(label: 'Fim', value: endDate, isBold: true),
                      _DetailRow(label: 'Estado', value: status, isBold: true),
                      _DetailRow(
                        label: 'Nome',
                        value: title,
                        isBold: true,
                        valueFontSize: 16,
                      ),
                      _DetailRow(
                        label: 'Descrição',
                        value: description,
                        isBold: true,
                        isMultiLine: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Card 2: Consultas Associadas
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Consultas associadas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Consultas ligadas a este tratamento',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (consultas.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Nenhuma consulta associada.',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                        )
                      else
                        ...consultas.map((c) {
                          // Extrair dados da consulta c
                          final cDate = formatDatePt(c.dateTime);
                          final cTime = c.dateTime != null
                              ? "${c.dateTime!.hour.toString().padLeft(2, '0')}:${c.dateTime!.minute.toString().padLeft(2, '0')}"
                              : '00:00';
                          final cInfo = c.razao ?? c.medicoNome ?? 'Consulta';
                          final cStatus = c.status;
                          return _AppointmentRow(
                            date: '$cDate, $cTime',
                            doctor: cInfo,
                            status: cStatus,
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isMultiLine;
  final double valueFontSize;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isMultiLine = false,
    this.valueFontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    color: const Color(0xFF1F2937),
                    fontSize: valueFontSize,
                  ),
                  maxLines: isMultiLine ? 5 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
      ],
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  final String date;
  final String doctor;
  final String status;

  const _AppointmentRow({
    required this.date,
    required this.doctor,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    // Cores badge consulta
    final isPending = status.toLowerCase().contains('pen');
    final statusBg = isPending ? const Color(0xFFFFF8E1) : Colors.green.shade50;
    final statusText = isPending ? const Color(0xFFF57C00) : Colors.green.shade800;
    final statusBorder =
        isPending ? const Color(0xFFFFE0B2) : Colors.green.shade200;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doctor,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusBorder),
            ),
            child: Text(
              status,
              style: TextStyle(
                  color: statusText, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(0, 36),
            ),
            child: Row(
              children: const [
                Icon(Icons.remove_red_eye_outlined,
                    size: 16, color: Colors.black87),
                SizedBox(width: 6),
                Text('Ver', style: TextStyle(color: Colors.black87)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
