import 'package:flutter/material.dart';
import '../models/property.dart';
import '../api/properties_service.dart';

enum PropertiesStatus { initial, loading, loaded, error }

class PropertiesProvider with ChangeNotifier {
  final PropertiesService _service = PropertiesService();
  
  List<Property> _properties = [];
  PropertiesStatus _status = PropertiesStatus.initial;
  String? _errorMessage;

  List<Property> get properties => _properties;
  PropertiesStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProperties(String organizationId) async {
    _status = PropertiesStatus.loading;
    notifyListeners();

    try {
      _properties = await _service.getProperties(organizationId);
      _status = PropertiesStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = PropertiesStatus.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<Property> createProperty(Map<String, dynamic> data) async {
    try {
      final property = await _service.createProperty(data);
      _properties.insert(0, property);
      notifyListeners();
      return property;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteProperty(String id, String organizationId) async {
    try {
      await _service.deleteProperty(id, organizationId);
      _properties.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> uploadPropertyImage(String propertyId, String filePath, String organizationId) async {
    try {
      await _service.uploadPropertyImage(propertyId, filePath, organizationId);
      // Wait for a second and then re-fetch properties to get the new images?
      // Or we can manually find the property and update its images if the backend wouldn't be too slow
      await fetchProperties(organizationId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
