import 'package:intl/intl.dart';

int? asInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '');
}

String? asString(Object? v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

DateTime? tryParseDate(Object? v) {
  final s = asString(v);
  if (s == null) return null;
  return DateTime.tryParse(s) ?? DateTime.tryParse(s.replaceFirst(' ', 'T'));
}

String formatDatePt(DateTime? d) {
  if (d == null) return '—';
  return DateFormat('dd/MM/yyyy').format(d);
}

String normalizeStatus(String? raw) {
  final s = (raw ?? '').trim();
  if (s.isEmpty) return '';
  final lower = s.toLowerCase();
  if (lower.contains('ativ')) return 'ativo';
  if (lower.contains('paus')) return 'pausado';
  if (lower.contains('concl') || lower.contains('final')) return 'concluido';
  if (lower.contains('cancel') || lower.contains('rejeit') || lower.contains('recus')) {
    return 'cancelado';
  }
  return lower;
}

class PlanSummary {
  final int idTratamento;
  final String? nome;
  final String? descricao;
  final String status;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final int? dependentId;
  final String? dependenteNome;
  final List<AssociatedConsulta> consultas;

  const PlanSummary({
    required this.idTratamento,
    required this.nome,
    required this.descricao,
    required this.status,
    required this.dataInicio,
    required this.dataFim,
    required this.dependentId,
    required this.dependenteNome,
    this.consultas = const [],
  });

  String get title {
    final n = (nome ?? '').trim();
    if (n.isNotEmpty) return n;
    final d = (descricao ?? '').trim();
    if (d.isNotEmpty) return d;
    return 'Plano de tratamento';
  }

  bool get isDependent => dependentId != null;

  factory PlanSummary.fromJson(Map<String, dynamic> json) {
    final id = asInt(
      json['id_tratamento'] ?? json['idTratamento'] ?? json['id'] ?? json['planoId'],
    );
    
    final rawConsultas = (json['consultas'] is List) ? (json['consultas'] as List) : [];
    final consultas = rawConsultas
        .whereType<Map>()
        .map((e) => AssociatedConsulta.fromJson(e.cast<String, dynamic>()))
        .toList();

    return PlanSummary(
      idTratamento: id ?? 0,
      nome: asString(json['nome'] ?? json['name'] ?? json['titulo'] ?? json['title']),
      descricao: asString(json['descricao'] ?? json['description'] ?? json['desc']),
      status: normalizeStatus(asString(json['status'] ?? json['estado'])),
      dataInicio: tryParseDate(json['data_inicio'] ?? json['inicio'] ?? json['start_date']),
      dataFim: tryParseDate(json['data_fim'] ?? json['fim'] ?? json['end_date']),
      dependentId: asInt(json['dependent_id'] ?? json['dependente_id'] ?? json['dependentId']),
      dependenteNome: asString(json['dependente_nome'] ?? json['dependent_name']),
      consultas: consultas,
    );
  }
}

class AssociatedConsulta {
  final int? id;
  final DateTime? dateTime;
  final String? medicoNome;
  final String status;
  final String? razao;

  const AssociatedConsulta({
    required this.id,
    required this.dateTime,
    required this.medicoNome,
    required this.status,
    this.razao,
  });

  factory AssociatedConsulta.fromJson(Map<String, dynamic> json) {
    final dt = tryParseDate(
      json['data_consulta'] ?? json['data'] ?? json['datetime'] ?? json['dataHora'] ?? json['date'],
    );
    final hour = asString(json['hora'] ?? json['time']);
    DateTime? merged = dt;
    if (merged != null && hour != null) {
      final parts = hour.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          merged = DateTime(merged.year, merged.month, merged.day, h, m);
        }
      }
    }

    return AssociatedConsulta(
      id: asInt(json['id_consulta'] ?? json['consulta_id'] ?? json['id'] ?? json['idConsulta']),
      dateTime: merged,
      medicoNome: asString(json['medico_nome'] ?? json['doctor_name'] ?? json['profissional'] ?? json['medico']),
      status: normalizeStatus(asString(json['status'] ?? json['estado'])),
      razao: asString(json['razao_consulta'] ?? json['razao'] ?? json['reason']),
    );
  }
}

class PlanDetail {
  final PlanSummary plano;
  final List<AssociatedConsulta> consultas;

  const PlanDetail({required this.plano, required this.consultas});

  factory PlanDetail.fromJson(Map<String, dynamic> json) {
    final rawPlano = (json['plano'] is Map)
        ? (json['plano'] as Map).cast<String, dynamic>()
        : json;

    final rawConsultas = (json['consultas'] is List)
        ? (json['consultas'] as List)
        : const [];

    final consultas = rawConsultas
        .whereType<Map>()
        .map((e) => AssociatedConsulta.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);

    return PlanDetail(
      plano: PlanSummary.fromJson(rawPlano),
      consultas: consultas,
    );
  }
}
