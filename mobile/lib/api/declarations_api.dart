import 'api_client.dart';
import 'models.dart';

class DeclarationsApi {
  final ApiClient client;

  DeclarationsApi(this.client);

  Future<List<ApiDeclarationItem>> listDeclarations({int? patientId}) async {
    final res = await client.getJson(
      '/declarations',
      query: {
        if (patientId != null) 'patientId': patientId,
      },
    );

    final list = _extractList(res);
    return list
        .whereType<Map>()
        .map((m) => ApiDeclarationItem.fromJson(m.cast<String, dynamic>()))
        .toList();
  }

  Future<ApiBinaryResponse> downloadDeclaration({
    required ApiDeclarationItem declaration,
  }) {
    final path = declaration.downloadPath;
    if (path != null && path.trim().isNotEmpty) {
      return client.getBytes(path);
    }
    return client.getBytes('/declarations/${declaration.id}/download');
  }

  Future<ApiBinaryResponse> downloadPresenceByConsulta({
    required int consultaId,
  }) {
    return client.getBytes(
      '/declarations/presence/by-consulta/$consultaId/download',
    );
  }

  static List<dynamic> _extractList(Map<String, dynamic> res) {
    final dynamic root =
        res['data'] ?? res['declarations'] ?? res['items'] ?? res;
    if (root is List) return root;
    if (root is Map) {
      final dynamic nested =
          root['data'] ?? root['declarations'] ?? root['items'];
      if (nested is List) return nested;
    }
    return const [];
  }
}
