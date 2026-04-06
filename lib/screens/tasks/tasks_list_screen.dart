import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../../providers/tasks_provider.dart';
import '../../api/auth_provider.dart';
import 'task_form_screen.dart';

class TasksListScreen extends StatefulWidget {
  const TasksListScreen({super.key});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentOrganizationId != null) {
        context.read<TasksProvider>().fetchTasks(auth.currentOrganizationId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasksProvider = context.watch<TasksProvider>();
    final auth = context.watch<AuthProvider>();

    final filteredTasks = tasksProvider.tasks.where((task) {
      if (_selectedStatus == null) return true;
      return task.status == _selectedStatus;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Tasks'),
        backgroundColor: AppTheme.backgroundColor,
        actions: [
          IconButton(
            icon: Icon(LucideIcons.filter, color: _selectedStatus != null ? AppTheme.primaryColor : null),
            onPressed: _showFilterMenu,
          ),
        ],
      ),
      body: _buildTasksList(tasksProvider, filteredTasks, auth),
      floatingActionButton: auth.hasPermission('TASKS_CREATE')
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TaskFormScreen()),
              ),
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(LucideIcons.plus),
            )
          : null,
    );
  }

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter by Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _filterOption(null, 'All Tasks'),
            _filterOption('TODO', 'To Do'),
            _filterOption('IN_PROGRESS', 'In Progress'),
            _filterOption('DONE', 'Completed'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _filterOption(String? value, String label) {
    return ListTile(
      title: Text(label),
      trailing: _selectedStatus == value ? const Icon(LucideIcons.check, color: AppTheme.primaryColor) : null,
      onTap: () {
        setState(() => _selectedStatus = value);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildTasksList(TasksProvider provider, List tasks, AuthProvider auth) {
    if (provider.status == TasksStatus.loading && provider.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks found.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isDone = task.status == 'DONE';

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.1)),
          ),
          color: AppTheme.surfaceLift,
          child: ListTile(
            leading: IconButton(
              icon: Icon(
                isDone ? LucideIcons.checkCircle2 : LucideIcons.circle,
                color: isDone ? Colors.green : AppTheme.onSurfaceVariant,
              ),
              onPressed: () => _toggleTask(context, auth, provider, task),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone ? AppTheme.onSurfaceVariant : AppTheme.onSurface,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description != null && task.description!.isNotEmpty)
                  Text(task.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.calendar, size: 12, color: _getPriorityColor(task.priority)),
                    const SizedBox(width: 4),
                    Text(
                      task.dueDate != null ? '${task.dueDate!.day}/${task.dueDate!.month}' : 'No date',
                      style: TextStyle(fontSize: 11, color: _getPriorityColor(task.priority)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      task.priority,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getPriorityColor(task.priority)),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(LucideIcons.edit2, size: 18),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TaskFormScreen(task: task)),
              ),
            ),
            onLongPress: () => _confirmDelete(context, auth, provider, task.id),
          ),
        );
      },
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'HIGH': return AppTheme.errorColor;
      case 'MEDIUM': return Colors.orange;
      case 'LOW': return Colors.green;
      default: return AppTheme.onSurfaceVariant;
    }
  }

  Future<void> _toggleTask(BuildContext context, AuthProvider auth, TasksProvider provider, dynamic task) async {
    try {
      final newStatus = task.status == 'DONE' ? 'TODO' : 'DONE';
      await provider.updateTask(task.id, auth.currentOrganizationId!, {'status': newStatus});
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating task: $e')));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, AuthProvider auth, TasksProvider provider, String taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('DELETE', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteTask(taskId, auth.currentOrganizationId!);
    }
  }
}
