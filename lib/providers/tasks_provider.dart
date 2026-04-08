import 'package:flutter/material.dart';
import '../models/task.dart';
import '../api/tasks_service.dart';

enum TasksStatus { initial, loading, loaded, error }

class TasksProvider with ChangeNotifier {
  final TasksService _service = TasksService();

  List<CRMTask> _tasks = [];
  TasksStatus _status = TasksStatus.initial;
  String? _errorMessage;

  List<CRMTask> get tasks => _tasks;
  TasksStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<void> fetchTasks(
    String organizationId, {
    String? status,
    String? priority,
  }) async {
    _status = TasksStatus.loading;
    notifyListeners();

    try {
      _tasks = await _service.getTasks(
        organizationId,
        status: status,
        priority: priority,
      );
      _status = TasksStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = TasksStatus.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<CRMTask> createTask(Map<String, dynamic> data) async {
    try {
      final task = await _service.createTask(data);
      _tasks.insert(0, task);
      notifyListeners();
      return task;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<CRMTask> updateTask(
    String id,
    String organizationId,
    Map<String, dynamic> data,
  ) async {
    try {
      final task = await _service.updateTask(id, organizationId, data);
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tasks[index] = task;
      }
      notifyListeners();
      return task;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTask(String id, String organizationId) async {
    try {
      await _service.deleteTask(id, organizationId);
      _tasks.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
