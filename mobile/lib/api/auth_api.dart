import 'api_client.dart';
import 'models.dart';
import 'token_store.dart';

class AuthApi {
  final ApiClient client;

  AuthApi(this.client);

  Future<LoginResult> loginPaciente(
      {required String email, required String senha}) async {
    final json = await client.postJson(
      '/auth/paciente/login',
      auth: false,
      body: {'email': email, 'senha': senha},
    );

    final result = LoginResult.fromJson(json);
    await client.tokenStore.write(
      AuthTokens(accessToken: result.token, refreshToken: result.refreshToken),
    );
    return result;
  }

  Future<ApiUser> me() async {
    final json = await client.getJson('/auth/me');
    if (json['user'] is Map) {
      final user = (json['user'] as Map).cast<String, dynamic>();
      // Some backends return extra fields at the root (e.g. patientId/id_paciente).
      // Merge them so ApiUser can pick them up.
      final merged = <String, dynamic>{
        ...user,
        if (json.containsKey('patientId')) 'patientId': json['patientId'],
        if (json.containsKey('patient_id')) 'patient_id': json['patient_id'],
        if (json.containsKey('id_paciente')) 'id_paciente': json['id_paciente'],
        if (json.containsKey('paciente_id')) 'paciente_id': json['paciente_id'],
        if (json.containsKey('paciente')) 'paciente': json['paciente'],
        if (json.containsKey('patient')) 'patient': json['patient'],
      };
      return ApiUser.fromJson(merged);
    }
    return ApiUser.fromJson(json);
  }

  Future<void> logout() async {
    final tokens = await client.tokenStore.read();
    final refresh = tokens?.refreshToken;
    if (refresh != null && refresh.isNotEmpty) {
      await client.postJson('/auth/logout',
          auth: false, body: {'refreshToken': refresh});
    }
    await client.tokenStore.clear();
  }
}
