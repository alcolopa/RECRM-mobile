import '../models/contact.dart';
import 'api_client.dart';

class ContactsService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Contact>> getContacts(String organizationId, {String? type}) async {
    final response = await _apiClient.get('/contacts', queryParameters: {
      'organizationId': organizationId,
      'type': ?type,
    });
    
    final List data = response.data['items'];
    return data.map((json) => Contact.fromJson(json)).toList();
  }

  Future<Contact> createContact(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/contacts', data: data);
    return Contact.fromJson(response.data);
  }

  Future<Contact> updateContact(String id, String organizationId, Map<String, dynamic> data) async {
    final response = await _apiClient.patch('/contacts/$id', 
      data: data, 
      queryParameters: {'organizationId': organizationId}
    );
    return Contact.fromJson(response.data);
  }

  Future<void> deleteContact(String id, String organizationId) async {
    await _apiClient.delete('/contacts/$id', queryParameters: {'organizationId': organizationId});
  }
}
