import '../models/deal.dart';
import 'api_client.dart';

class DealsService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Deal>> getDeals(String organizationId, {String? stage}) async {
    final response = await _apiClient.get(
      '/deals',
      queryParameters: {'organizationId': organizationId, 'stage': ?stage},
    );

    final List data = response.data['items'];
    return data.map((json) => Deal.fromJson(json)).toList();
  }

  Future<Deal> createDeal(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/deals', data: data);
    return Deal.fromJson(response.data);
  }

  Future<Deal> updateDeal(
    String id,
    String organizationId,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.patch(
      '/deals/$id',
      data: data,
      queryParameters: {'organizationId': organizationId},
    );
    return Deal.fromJson(response.data);
  }

  Future<void> deleteDeal(String id, String organizationId) async {
    await _apiClient.delete(
      '/deals/$id',
      queryParameters: {'organizationId': organizationId},
    );
  }
}
