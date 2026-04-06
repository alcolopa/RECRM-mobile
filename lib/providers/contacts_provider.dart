import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../api/contacts_service.dart';

enum ContactsStatus { initial, loading, loaded, error }

class ContactsProvider with ChangeNotifier {
  final ContactsService _service = ContactsService();
  
  List<Contact> _contacts = [];
  ContactsStatus _status = ContactsStatus.initial;
  String? _errorMessage;

  List<Contact> get contacts => _contacts;
  ContactsStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<void> fetchContacts(String organizationId, {String? type}) async {
    _status = ContactsStatus.loading;
    notifyListeners();

    try {
      _contacts = await _service.getContacts(organizationId, type: type);
      _status = ContactsStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = ContactsStatus.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<Contact> createContact(Map<String, dynamic> data) async {
    try {
      final contact = await _service.createContact(data);
      _contacts.insert(0, contact);
      notifyListeners();
      return contact;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Contact> updateContact(String id, String organizationId, Map<String, dynamic> data) async {
    try {
      final contact = await _service.updateContact(id, organizationId, data);
      final index = _contacts.indexWhere((c) => c.id == id);
      if (index != -1) {
        _contacts[index] = contact;
      }
      notifyListeners();
      return contact;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteContact(String id, String organizationId) async {
    try {
      await _service.deleteContact(id, organizationId);
      _contacts.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
