import 'package:flutter/material.dart';
import '../models/deal.dart';
import '../api/deals_service.dart';

enum DealsStatus { initial, loading, loaded, error }

class DealsProvider with ChangeNotifier {
  final DealsService _service = DealsService();

  List<Deal> _deals = [];
  DealsStatus _status = DealsStatus.initial;
  String? _errorMessage;

  List<Deal> get deals => _deals;
  DealsStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDeals(String organizationId, {String? stage}) async {
    _status = DealsStatus.loading;
    notifyListeners();

    try {
      _deals = await _service.getDeals(organizationId, stage: stage);
      _status = DealsStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = DealsStatus.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<Deal> createDeal(Map<String, dynamic> data) async {
    try {
      final deal = await _service.createDeal(data);
      _deals.insert(0, deal);
      notifyListeners();
      return deal;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Deal> updateDeal(
    String id,
    String organizationId,
    Map<String, dynamic> data,
  ) async {
    try {
      final deal = await _service.updateDeal(id, organizationId, data);
      final index = _deals.indexWhere((d) => d.id == id);
      if (index != -1) {
        _deals[index] = deal;
      }
      notifyListeners();
      return deal;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteDeal(String id, String organizationId) async {
    try {
      await _service.deleteDeal(id, organizationId);
      _deals.removeWhere((d) => d.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
