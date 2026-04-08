import '../models/task.dart';
import 'api_client.dart';

class TasksService {
  final ApiClient _apiClient = ApiClient();

  Future<List<CRMTask>> getTasks(
    String organizationId, {
    String? status,
    String? priority,
  }) async {
    final response = await _apiClient.get(
      '/tasks',
      queryParameters: {
        'organizationId': organizationId,
        'status': ?status,
        'priority': ?priority,
      },
    );

    final List data = response.data['items'];
    return data.map((json) => CRMTask.fromJson(json)).toList();
  }

  Future<CRMTask> createTask(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/tasks', data: data);
    return CRMTask.fromJson(response.data);
  }

  Future<CRMTask> updateTask(
    String id,
    String organizationId,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.patch(
      '/tasks/$id',
      data: data,
      queryParameters: {'organizationId': organizationId},
    );
    return CRMTask.fromJson(response.data);
  }

  Future<void> deleteTask(String id, String organizationId) async {
    await _apiClient.delete(
      '/tasks/$id',
      queryParameters: {'organizationId': organizationId},
    );
  }
}
