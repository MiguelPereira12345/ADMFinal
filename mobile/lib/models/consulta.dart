/// Modelo de dados para Consulta
/// 
/// Representa uma consulta médica no sistema CliniMolelos.
/// Pode ser criado a partir da API (JSON) ou do SQLite (Map).
class Consulta {
  final int idConsulta;
  final int idUtilizador;
  final DateTime dataHora;
  final int? duracaoMinutos;
  final String? tipoConsulta;
  final String? estadoConsulta;
  final String? motivoConsulta;
  final String? sintomas;
  final String? resultados;
  final String? nomeMedico;

  Consulta({
    required this.idConsulta,
    required this.idUtilizador,
    required this.dataHora,
    this.duracaoMinutos,
    this.tipoConsulta,
    this.estadoConsulta,
    this.motivoConsulta,
    this.sintomas,
    this.resultados,
    this.nomeMedico,
  });

  /// Cria uma Consulta a partir de JSON da API
  factory Consulta.fromJson(Map<String, dynamic> json) {
    return Consulta(
      idConsulta: json['id'] ?? json['id_consulta'] ?? 0,
      idUtilizador: json['id_utilizador'] ?? json['user_id'] ?? 0,
      dataHora: DateTime.tryParse(json['data_hora'] ?? '') ?? DateTime.now(),
      duracaoMinutos: json['duracao_minutos'] ?? json['duracao'],
      tipoConsulta: json['tipo_consulta'] ?? json['tipo'],
      estadoConsulta: json['estado_consulta'] ?? json['estado'],
      motivoConsulta: json['motivo_consulta'] ?? json['motivo'],
      sintomas: json['sintomas'],
      resultados: json['resultados'],
      nomeMedico: json['nome_medico'] ?? json['medico'],
    );
  }

  /// Cria uma Consulta a partir de um Map do SQLite
  factory Consulta.fromSqlite(Map<String, dynamic> map) {
    return Consulta(
      idConsulta: map['id_consulta'] ?? 0,
      idUtilizador: map['id_utilizador'] ?? 0,
      dataHora: DateTime.tryParse(map['data_hora'] ?? '') ?? DateTime.now(),
      duracaoMinutos: map['duracao_minutos'],
      tipoConsulta: map['tipo_consulta'],
      estadoConsulta: map['estado_consulta'],
      motivoConsulta: map['motivo_consulta'],
      sintomas: map['sintomas'],
      resultados: map['resultados'],
      nomeMedico: map['nome_medico'],
    );
  }

  /// Converte a Consulta para um Map para guardar no SQLite
  Map<String, dynamic> toSqlite() {
    return {
      'id_consulta': idConsulta,
      'id_utilizador': idUtilizador,
      'data_hora': dataHora.toIso8601String(),
      'duracao_minutos': duracaoMinutos,
      'tipo_consulta': tipoConsulta,
      'estado_consulta': estadoConsulta,
      'motivo_consulta': motivoConsulta,
      'sintomas': sintomas,
      'resultados': resultados,
      'nome_medico': nomeMedico,
    };
  }

  @override
  String toString() {
    return 'Consulta(id: $idConsulta, medico: $nomeMedico, data: $dataHora)';
  }
}
