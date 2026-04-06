import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/organization.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, authenticating }

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  AuthStatus _status = AuthStatus.unknown;
  Map<String, dynamic>? _user;
  Organization? _organization;
  Map<String, String>? _errors;

  AuthStatus get status => _status;
  Map<String, dynamic>? get user => _user;
  Organization? get organization => _organization;
  Map<String, String>? get errors => _errors;

  AuthProvider() {
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      try {
        final response = await _apiClient.get('/auth/profile');
        _user = response.data;
        _status = AuthStatus.authenticated;
      } catch (e) {
        _status = AuthStatus.unauthenticated;
        await _storage.delete(key: 'auth_token');
      }
      
      // Fetch organization once authenticated
      if (_status == AuthStatus.authenticated) {
        await fetchOrganization();
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errors = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final token = response.data['access_token'];
      await _storage.write(key: 'auth_token', value: token);
      
      // Re-fetch profile to get user details
      await _checkStatus();
      return true;
    } on DioException catch (e) {
      _status = AuthStatus.unauthenticated;
      if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
        if (e.response?.data is Map) {
          _errors = Map<String, String>.from(e.response?.data.map((key, value) => MapEntry(key, value.toString())));
        } else {
          _errors = {'message': e.response?.data['message'] ?? 'Invalid credentials'};
        }
      } else {
        _errors = {'message': 'Connection error. Please try again.'};
      }
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errors = {'message': 'An unexpected error occurred.'};
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _status = AuthStatus.authenticating;
    _errors = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/auth/register', data: userData);
      final token = response.data['access_token'];
      await _storage.write(key: 'auth_token', value: token);
      
      await _checkStatus();
      return true;
    } on DioException catch (e) {
      _status = AuthStatus.unauthenticated;
      if (e.response?.statusCode == 400 || e.response?.statusCode == 409) {
        if (e.response?.data is Map) {
           // NestJS global validation pipe returns a "bag of errors" as per GEMINI.md
           _errors = Map<String, String>.from(e.response?.data.map((key, value) => MapEntry(key, value.toString())));
        } else {
          _errors = {'message': e.response?.data['message'] ?? 'Registration failed'};
        }
      } else {
        _errors = {'message': 'Connection error. Please try again.'};
      }
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errors = {'message': 'An unexpected error occurred.'};
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // Helpers
  String? get currentOrganizationId {
    if (_user == null || _user!['memberships'] == null) return null;
    final List memberships = _user!['memberships'];
    if (memberships.isEmpty) return null;
    // For now, return the first organization the user belongs to
    return memberships[0]['organizationId'];
  }

  bool hasPermission(String permission) {
    if (_user == null || _user!['memberships'] == null) return false;
    final List memberships = _user!['memberships'];
    final orgId = currentOrganizationId;
    
    final membership = memberships.firstWhere(
      (m) => m['organizationId'] == orgId,
      orElse: () => null,
    );

    if (membership == null) return false;

    final String role = membership['role'];
    if (role == 'OWNER' || role == 'ADMIN') return true;

    if (membership['customRole'] != null && membership['customRole']['permissions'] != null) {
      final List permissions = membership['customRole']['permissions'];
      return permissions.contains(permission);
    }

    return false;
  }

  Future<void> fetchOrganization() async {
    final orgId = currentOrganizationId;
    if (orgId == null) return;

    try {
      final response = await _apiClient.get('/organization', queryParameters: {'organizationId': orgId});
      _organization = Organization.fromJson(response.data);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching organization: $e');
    }
  }

  Future<bool> updateOrganization(Map<String, dynamic> data) async {
    final orgId = currentOrganizationId;
    if (orgId == null) return false;

    try {
      final response = await _apiClient.patch('/organization', 
        data: data,
        queryParameters: {'organizationId': orgId}
      );
      _organization = Organization.fromJson(response.data);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      if (e.response?.data is Map) {
         _errors = Map<String, String>.from(e.response?.data.map((key, value) => MapEntry(key, value.toString())));
      }
      notifyListeners();
      return false;
    } catch (e) {
      _errors = {'message': 'Update failed'};
      notifyListeners();
      return false;
    }
  }

  void updateOrganizationLogo(String logoUrl) {
    if (_organization != null) {
      _organization = Organization(
        id: _organization!.id,
        name: _organization!.name,
        slug: _organization!.slug,
        address: _organization!.address,
        email: _organization!.email,
        logo: logoUrl,
        phone: _organization!.phone,
        website: _organization!.website,
        ownerId: _organization!.ownerId,
        accentColor: _organization!.accentColor,
        defaultTheme: _organization!.defaultTheme,
        memberships: _organization!.memberships,
        subscription: _organization!.subscription,
      );
      notifyListeners();
    }
  }
}
