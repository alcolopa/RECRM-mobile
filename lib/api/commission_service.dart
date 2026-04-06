import 'api_client.dart';
import '../models/organization.dart';

class CommissionService {
  final ApiClient _apiClient = ApiClient();

  Future<CommissionConfig> getOrgCommission(String orgId) async {
    final response = await _apiClient.get('/commission/config/$orgId');
    return CommissionConfig.fromJson(response.data);
  }

  Future<void> updateOrgCommission(String orgId, Map<String, dynamic> data) async {
    await _apiClient.patch('/commission/config/$orgId', data: data);
  }

  Future<Map<String, dynamic>> getAgentCommission(String agentId, String orgId) async {
    final response = await _apiClient.get('/commission/agent/$agentId', queryParameters: {
      'organizationId': orgId,
    });
    return response.data;
  }

  Future<void> updateAgentCommission(String agentId, Map<String, dynamic> data) async {
    await _apiClient.patch('/commission/agent/$agentId', data: data);
  }
}
