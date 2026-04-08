import 'package:dio/dio.dart';
import '../../models/property.dart';
import 'api_client.dart';

class PropertiesService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Property>> getProperties(String organizationId) async {
    try {
      final response = await _apiClient.get(
        '/properties',
        queryParameters: {'organizationId': organizationId, 'limit': 50},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['items'];
        return data.map((json) => Property.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load properties');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Unknown API error');
    }
  }

  Future<Property> createProperty(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/properties', data: data);
    return Property.fromJson(response.data);
  }

  Future<void> deleteProperty(String id, String organizationId) async {
    await _apiClient.delete(
      '/properties/$id',
      queryParameters: {'organizationId': organizationId},
    );
  }

  Future<void> uploadPropertyImage(
    String propertyId,
    String filePath,
    String organizationId,
  ) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    await _apiClient.post(
      '/properties/$propertyId/images',
      data: formData,
      queryParameters: {'organizationId': organizationId},
    );
  }
}
