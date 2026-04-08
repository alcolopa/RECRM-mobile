import 'package:flutter/material.dart';
import '../models/payout_stats.dart';
import '../api/payouts_service.dart';

enum PayoutsStatus { initial, loading, loaded, error }

class PayoutsProvider with ChangeNotifier {
  final PayoutsService _service = PayoutsService();

  AdminPayoutStats? _adminStats;
  PersonalPayoutStats? _personalStats;
  PayoutsStatus _status = PayoutsStatus.initial;
  String? _errorMessage;

  AdminPayoutStats? get adminStats => _adminStats;
  PersonalPayoutStats? get personalStats => _personalStats;
  PayoutsStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAdminStats(
    String organizationId, {
    String? startDate,
    String? endDate,
  }) async {
    _status = PayoutsStatus.loading;
    notifyListeners();

    try {
      _adminStats = await _service.getAdminStats(
        organizationId,
        startDate: startDate,
        endDate: endDate,
      );
      _status = PayoutsStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = PayoutsStatus.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchPersonalStats(
    String organizationId, {
    String? startDate,
    String? endDate,
  }) async {
    _status = PayoutsStatus.loading;
    notifyListeners();

    try {
      _personalStats = await _service.getPersonalStats(
        organizationId,
        startDate: startDate,
        endDate: endDate,
      );
      _status = PayoutsStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = PayoutsStatus.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> markAsPaid(String dealId, String organizationId) async {
    try {
      await _service.markAsPaid(dealId, organizationId);
      // Re-fetch admin stats to reflect change
      await fetchAdminStats(organizationId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markAllAsPaid(String agentId, String organizationId) async {
    try {
      await _service.markAllAsPaid(agentId, organizationId);
      // Re-fetch admin stats to reflect change
      await fetchAdminStats(organizationId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
