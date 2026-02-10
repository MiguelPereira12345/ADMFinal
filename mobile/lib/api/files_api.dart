import 'api_client.dart';
import 'models.dart';

class FilesApi {
  final ApiClient client;

  FilesApi(this.client);

  Future<List<ApiFileItem>> listFiles({required int patientId}) async {
    final res = await client.getJson(
      '/files',
      query: {
        'patientId': patientId,
      },
    );

    final list = _extractList(res);
    return list
        .whereType<Map>()
        .map((m) => ApiFileItem.fromJson(m.cast<String, dynamic>()))
        .toList();
  }

  Future<ApiBinaryResponse> downloadFile(int fileId) {
    return client.getBytes('/files/$fileId/download');
  }

  static List<dynamic> _extractList(Map<String, dynamic> res) {
    final dynamic root = res['data'] ?? res['files'] ?? res['items'] ?? res;
    if (root is List) return root;
    if (root is Map) {
      final dynamic nested = root['data'] ?? root['files'] ?? root['items'];
      if (nested is List) return nested;
    }
    return const [];
  }
}
