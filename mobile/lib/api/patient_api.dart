import 'api_client.dart';

class PatientApi {
  final ApiClient client;

  PatientApi(this.client);

  Future<Map<String, dynamic>> getProfile(int userId) {
    return client.getJson('/patients/$userId');
  }

  Future<Map<String, dynamic>> listConsultas(int userId) {
    return client.getJson('/patients/$userId/consultas');
  }

  Future<Map<String, dynamic>> getConsulta(int userId, int consultaId) {
    return client.getJson('/patients/$userId/consultas/$consultaId');
  }

  Future<Map<String, dynamic>> requestConsulta(
      int userId, Map<String, dynamic> payload) {
    return client.postJson('/patients/$userId/consultas/request', body: payload);
  }

  Future<Map<String, dynamic>> listDependents(int userId) {
    return client.getJson('/patients/$userId/dependents');
  }

  Future<Map<String, dynamic>> getDependent(int userId, int dependentId) {
    return client.getJson('/patients/$userId/dependents/$dependentId');
  }

  Future<Map<String, dynamic>> listPlanos(int userId) {
    return client.getJson('/patients/$userId/planos');
  }

  Future<Map<String, dynamic>> getPlano(int userId, int planoId) {
    return client.getJson('/patients/$userId/planos/$planoId');
  }

  Future<ApiBinaryResponse> downloadPlanoPdf(int userId, int planoId) {
    return client.getBytes('/patients/$userId/planos/$planoId/download');
  }

  Future<Map<String, dynamic>> getConsents(int userId) {
    return client.getJson('/patients/$userId/consents');
  }

  Future<Map<String, dynamic>> upsertConsents(
      int userId, Map<String, dynamic> payload) {
    return client.putJson('/patients/$userId/consents', body: payload);
  }

  Future<Map<String, dynamic>> listFiles({int? patientId, int? dependentId}) {
    return client.getJson(
      '/files',
      query: {
        if (patientId != null) 'patientId': patientId,
        if (dependentId != null) 'dependentId': dependentId,
      },
    );
  }

  Future<ApiBinaryResponse> downloadFile(int fileId) {
    return client.getBytes('/files/$fileId/download');
  }

  Future<Map<String, dynamic>> getHistoricoMedico(int userId) {
    return client.getJson('/patients/$userId/historico-medico');
  }
}
