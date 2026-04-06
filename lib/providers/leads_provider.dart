import 'package:flutter/material.dart';
import '../models/lead.dart';
import '../api/leads_service.dart';

enum LeadsStatus { initial, loading, loaded, error }

class LeadsProvider with ChangeNotifier {
  final LeadsService _service = LeadsService();
  
  List<Lead> _leads = [];
  LeadsStatus _status = LeadsStatus.initial;
  String? _errorMessage;

  List<Lead> get leads => _leads;
  LeadsStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<void> fetchLeads(String organizationId, {String? status}) async {
    _status = LeadsStatus.loading;
    notifyListeners();

    try {
      _leads = await _service.getLeads(organizationId, status: status);
      _status = LeadsStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = LeadsStatus.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<Lead> createLead(Map<String, dynamic> data) async {
    try {
      final lead = await _service.createLead(data);
      _leads.insert(0, lead);
      notifyListeners();
      return lead;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Lead> updateLead(String id, String organizationId, Map<String, dynamic> data) async {
    try {
      final lead = await _service.updateLead(id, organizationId, data);
      final index = _leads.indexWhere((l) => l.id == id);
      if (index != -1) {
        _leads[index] = lead;
      }
      notifyListeners();
      return lead;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteLead(String id, String organizationId) async {
    try {
      await _service.deleteLead(id, organizationId);
      _leads.removeWhere((l) => l.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> convertLead(String id, String organizationId, Map<String, dynamic> data) async {
    try {
      await _service.convertLead(id, organizationId, data);
      _leads.removeWhere((l) => l.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
