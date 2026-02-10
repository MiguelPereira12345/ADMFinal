import 'package:flutter/material.dart';

import '../../app/session_scope.dart';
import '../../utils/app_formatters.dart';
import 'details_card.dart';
import 'row_data.dart';
import 'consulta_utils.dart'; // statusBadge

class ConsultaDetailsBody extends StatelessWidget {
  final Map<String, dynamic> consulta;
  final bool showFallbackNote;

  const ConsultaDetailsBody({
    super.key,
    required this.consulta,
    this.showFallbackNote = false,
  });

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final status = firstString(consulta, ['status', 'estado']) ?? '—';

    // Helper to shorten calls
    String? first(List<String> keys) => firstString(consulta, keys);

    final paciente = first(['dependente_nome', 'dependent_name']) ??
        first(['paciente_nome', 'patient_name']) ??
        session.user?.nome ??
        '—';

    final profissional = first(['medico_nome', 'doctor_name']) ??
        first(['id_medico', 'doctor_id']) ??
        '—';

    final especialidade = first([
          'especialidade',
          'especialidade_nome',
          'specialty',
          'specialty_name',
        ]) ??
        '—';

    final dataConsulta = formatDatePt(first([
      'data_consulta',
      'data',
      'date',
      'datetime',
      'dataHora',
    ]));

    final hora = formatHour(first(['hora', 'time']));

    final duracao = formatDurationMinutes(consulta['duracao'] ?? consulta['duracao_minutos']);

    final tipo = first(['tipo_de_marcacao', 'tipo', 'type']) ?? '—';
    final motivo = first(['razao_consulta', 'motivo', 'reason']) ?? '—';
    final notas = first(['notas_internas', 'notas', 'internal_notes']) ?? '—';

    final badge = statusBadge(status);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (showFallbackNote)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'A mostrar informação do resumo (o servidor devolveu 404).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ),
        DetailsCard(
          statusText: status,
          statusBg: badge.bg,
          statusFg: badge.fg,
          rows: [
            RowData('Paciente', paciente),
            RowData('Profissional', profissional),
            RowData('Especialidade', especialidade),
            RowData('Data', dataConsulta ?? '—'),
            RowData('Hora', hora ?? '—'),
            RowData('Duração', duracao ?? '—'),
            RowData('Tipo', tipo),
            RowData('Motivo', motivo),
            RowData('Notas internas', notas),
          ],
        ),
      ],
    );
  }
}
