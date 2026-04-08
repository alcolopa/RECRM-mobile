import '../models/contact.dart';
import '../models/lead.dart';
import 'api_client.dart';

class LeadsService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Lead>> getLeads(String organizationId, {String? status}) async {
    final response = await _apiClient.get(
      '/leads',
      queryParameters: {'organizationId': organizationId, 'status': ?status},
    );

    final List data = response.data['items'];
    return data.map((json) => Lead.fromJson(json)).toList();
  }

  Future<Lead> createLead(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/leads', data: data);
    return Lead.fromJson(response.data);
  }

  Future<Lead> updateLead(
    String id,
    String organizationId,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.patch(
      '/leads/$id',
      data: data,
      queryParameters: {'organizationId': organizationId},
    );
    return Lead.fromJson(response.data);
  }

  Future<void> deleteLead(String id, String organizationId) async {
    await _apiClient.delete(
      '/leads/$id',
      queryParameters: {'organizationId': organizationId},
    );
  }

  Future<Contact> convertLead(
    String id,
    String organizationId,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.post(
      '/leads/$id/convert',
      data: data,
      queryParameters: {'organizationId': organizationId},
    );
    return Contact.fromJson(response.data['contact']);
  }
}
