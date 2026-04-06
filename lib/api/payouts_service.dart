import '../models/payout_stats.dart';
import 'api_client.dart';

class PayoutsService {
  final ApiClient _client = ApiClient();

  Future<AdminPayoutStats> getAdminStats(String organizationId, {String? startDate, String? endDate}) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final response = await _client.get(
      '/payouts/admin-stats',
      queryParameters: queryParams,
    );

    return AdminPayoutStats.fromJson(response.data);
  }

  Future<PersonalPayoutStats> getPersonalStats(String organizationId, {String? startDate, String? endDate}) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final response = await _client.get(
      '/payouts/agent-stats',
      queryParameters: queryParams,
    );

    return PersonalPayoutStats.fromJson(response.data);
  }

  Future<void> markAsPaid(String dealId, String organizationId) async {
    await _client.post(
      '/payouts/mark-as-paid/$dealId',
      data: {},
    );
  }

  Future<void> markAllAsPaid(String agentId, String organizationId) async {
    await _client.post(
      '/payouts/mark-all-paid/$agentId',
      data: {},
    );
  }
}
