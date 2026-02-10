class ApiUser {
  final int id;
  final int? patientId;
  final String nome;
  final String email;
  final String tipo;

  const ApiUser({
    required this.id,
    this.patientId,
    required this.nome,
    required this.email,
    required this.tipo,
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      final s = v.toString().trim();
      return int.tryParse(s);
    }

    final nestedPatient = (json['patient'] is Map)
        ? (json['patient'] as Map).cast<String, dynamic>()
        : (json['paciente'] is Map)
            ? (json['paciente'] as Map).cast<String, dynamic>()
            : null;

    final patientId = asInt(json['patientId'] ??
        json['patient_id'] ??
        json['id_paciente'] ??
        json['paciente_id'] ??
        json['idPaciente'] ??
        nestedPatient?['id'] ??
        nestedPatient?['patientId'] ??
        nestedPatient?['id_paciente']);

    return ApiUser(
      id: (json['id'] as num).toInt(),
      patientId: patientId,
      nome: (json['nome'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      tipo: (json['tipo'] ?? '').toString(),
    );
  }
}

class LoginResult {
  final String token;
  final String? refreshToken;
  final ApiUser user;

  const LoginResult({required this.token, required this.user, this.refreshToken});

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final baseUser = (json['user'] as Map).cast<String, dynamic>();
    final mergedUser = <String, dynamic>{
      ...baseUser,
      if (json.containsKey('patientId')) 'patientId': json['patientId'],
      if (json.containsKey('patient_id')) 'patient_id': json['patient_id'],
      if (json.containsKey('id_paciente')) 'id_paciente': json['id_paciente'],
      if (json.containsKey('paciente_id')) 'paciente_id': json['paciente_id'],
      if (json.containsKey('paciente')) 'paciente': json['paciente'],
      if (json.containsKey('patient')) 'patient': json['patient'],
    };
    return LoginResult(
      token: (json['token'] ?? '').toString(),
      refreshToken: json['refreshToken']?.toString(),
      user: ApiUser.fromJson(mergedUser),
    );
  }
}

class ApiFileItem {
  final int id;
  final String name;
  final String? mimeType;
  final String? category;
  final DateTime? createdAt;
  final int? sizeBytes;
  final int? consultaId;
  final int? dependentId;

  const ApiFileItem({
    required this.id,
    required this.name,
    this.mimeType,
    this.category,
    this.createdAt,
    this.sizeBytes,
    this.consultaId,
    this.dependentId,
  });

  factory ApiFileItem.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString().trim());
    }

    String? asString(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      return s.trim().isEmpty ? null : s;
    }

    DateTime? asDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      final s = v.toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    final id = asInt(json['id'] ?? json['id_file'] ?? json['fileId'] ?? json['idFile']);
    return ApiFileItem(
      id: id ?? 0,
      name: (asString(json['file_name'] ??
              json['originalName'] ??
              json['filename'] ??
              json['fileName'] ??
              json['name']) ??
          'Documento'),
      mimeType:
          asString(json['mime_type'] ?? json['mimeType'] ?? json['type']),
      category: asString(json['kind'] ?? json['category'] ?? json['categoria']),
      createdAt: asDate(json['created_at'] ??
          json['createdAt'] ??
          json['uploadedAt'] ??
          json['uploaded_at'] ??
          json['date']),
      sizeBytes: asInt(json['size_bytes'] ?? json['sizeBytes'] ?? json['size']),
      consultaId: asInt(
        json['consulta_id'] ??
            json['consultaId'] ??
            json['id_consulta'] ??
            (json['consulta'] is Map ? (json['consulta'] as Map)['id'] : null),
      ),
      dependentId: asInt(
        json['dependent_id'] ??
            json['dependentId'] ??
            json['dependenteId'] ??
            json['dependente_id'] ??
            json['id_dependente'] ??
            (json['dependent'] is Map ? (json['dependent'] as Map)['id'] : null) ??
            (json['dependente'] is Map ? (json['dependente'] as Map)['id'] : null),
      ),
    );
  }
}

class ApiDeclarationItem {
  final int id;
  final String title;
  final String? subtitle;
  final String? doctor;
  final String? specialty;
  final DateTime? date;
  final int? consultaId;
  final String? downloadPath;

  const ApiDeclarationItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.doctor,
    this.specialty,
    this.date,
    this.consultaId,
    this.downloadPath,
  });

  factory ApiDeclarationItem.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString().trim());
    }

    String? asString(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      return s.trim().isEmpty ? null : s;
    }

    DateTime? asDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      final s = v.toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    final nestedConsulta = (json['consulta'] is Map)
        ? (json['consulta'] as Map).cast<String, dynamic>()
        : null;

    final id = asInt(json['id'] ?? json['declarationId'] ?? json['idDeclaration']);
    final consultaId = asInt(json['consultaId'] ??
        json['consulta_id'] ??
        nestedConsulta?['id'] ??
        nestedConsulta?['consultaId']);

    final title = asString(json['title'] ??
            json['name'] ??
            json['tipo'] ??
            json['type'] ??
            json['descricao']) ??
        'Declaração';

    return ApiDeclarationItem(
      id: id ?? 0,
      title: title,
      subtitle: asString(json['subtitle'] ?? json['subtitulo'] ?? json['descricao']),
      doctor: asString(json['doctor'] ?? json['medico'] ?? json['doctorName']),
      specialty:
          asString(json['specialty'] ?? json['especialidade'] ?? json['service']),
      date: asDate(json['date'] ??
          json['data'] ??
          json['createdAt'] ??
          json['created_at'] ??
          nestedConsulta?['data']),
      consultaId: consultaId,
      downloadPath: asString(
        json['downloadPath'] ??
            json['download_path'] ??
            json['downloadUrl'] ??
            json['download_url'] ??
            json['path'],
      ),
    );
  }
}
