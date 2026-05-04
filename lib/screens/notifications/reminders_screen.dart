import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiocare/models/notification_model.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/services/firestore_service.dart';
import 'package:physiocare/services/notification_service.dart';
import 'package:physiocare/utils/app_constants.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<NotificationModel> _reminders = [];
  bool _isLoading = false;
  final NotificationService _notificationService = NotificationService();
  bool _streakAlerts = true;
  bool _planUpdates = true;
  bool _prefsLoading = false;

  // Day abbreviation labels (index 0 → Mon = 1, …, index 6 → Sun = 7)
  static const List<String> _dayLabels = [
    'M', 'T', 'W', 'T', 'F', 'S', 'S'
  ];

  String get _uid =>
      context.read<AppAuthProvider>().userModel?.id ?? '';

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReminders());
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNotifPrefs());
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------
  Future<void> _loadReminders() async {
    final uid = _uid;
    if (uid.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final reminders = await _notificationService.getUserReminders(uid);
      if (mounted) setState(() => _reminders = reminders);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNotifPrefs() async {
    final uid = _uid;
    if (uid.isEmpty) return;
    setState(() => _prefsLoading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        final prefs = doc.data()?['notificationPrefs'] as Map<String, dynamic>? ?? {};
        setState(() {
          _streakAlerts = prefs['streakAlerts'] as bool? ?? true;
          _planUpdates = prefs['planUpdates'] as bool? ?? true;
        });
      }
    } finally {
      if (mounted) setState(() => _prefsLoading = false);
    }
  }

  Future<void> _saveNotifPref(String key, bool value) async {
    final uid = _uid;
    if (uid.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'notificationPrefs.$key': value,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save preference: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Toggle reminder active state
  // ---------------------------------------------------------------------------
  Future<void> _toggleReminder(String id, bool newValue) async {
    final uid = _uid;
    if (uid.isEmpty) return;
    try {
      await _notificationService.toggleReminder(id, newValue, uid);
      await _loadReminders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update reminder: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Delete reminder
  // ---------------------------------------------------------------------------
  Future<void> _deleteReminder(NotificationModel reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reminder'),
        content:
            Text('Delete "${reminder.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _notificationService.cancelReminder(reminder.id);
      await FirestoreService().deleteDoc('reminders', reminder.id);
      await _loadReminders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not delete reminder: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Add reminder dialog
  // ---------------------------------------------------------------------------
  Future<void> _showAddReminderDialog() async {
    final uid = _uid;
    if (uid.isEmpty) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddReminderDialog(
        uid: uid,
        notificationService: _notificationService,
        onSaved: _loadReminders,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Format helpers
  // ---------------------------------------------------------------------------
  String _formatDays(List<int> days) {
    if (days.isEmpty) return 'No days selected';
    // Sort by day number and map to abbreviations
    final sorted = List<int>.from(days)..sort();
    final abbreviated = sorted.map((d) {
      // d is 1-based: 1=Mon … 7=Sun
      if (d >= 1 && d <= 7) return _dayLabels[d - 1];
      return '';
    }).where((s) => s.isNotEmpty).toList();
    return abbreviated.join(', ');
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        backgroundColor: AppColors.primary,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotifPrefsSection(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Scheduled Reminders',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reminders.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: _reminders.length,
                        itemBuilder: (context, index) =>
                            _buildReminderCard(_reminders[index]),
                      ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No reminders set',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add a reminder\nand stay consistent with your exercises.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Push notification preferences section
  // ---------------------------------------------------------------------------
  Widget _buildNotifPrefsSection() {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Push Notifications',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (_prefsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else ...[
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text(
                  'Streak Alerts',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Get notified on 7, 14, and 30-day streaks'),
                value: _streakAlerts,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  setState(() => _streakAlerts = val);
                  _saveNotifPref('streakAlerts', val);
                },
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text(
                  'Plan Updates',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Get notified when a new recovery plan is available'),
                value: _planUpdates,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  setState(() => _planUpdates = val);
                  _saveNotifPref('planUpdates', val);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reminder card
  // ---------------------------------------------------------------------------
  Widget _buildReminderCard(NotificationModel reminder) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          Icons.notifications,
          color: reminder.isActive ? AppColors.primary : Colors.grey,
          size: 28,
        ),
        title: Text(
          reminder.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: reminder.isActive
                ? AppColors.textPrimary
                : Colors.grey,
          ),
        ),
        subtitle: Text(
          '${_formatDays(reminder.daysOfWeek)} at ${reminder.scheduledTime}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: reminder.isActive,
              activeThumbColor: AppColors.primary,
              onChanged: (val) => _toggleReminder(reminder.id, val),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deleteReminder(reminder),
              tooltip: 'Delete reminder',
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Add Reminder Dialog — separate StatefulWidget
// =============================================================================
class _AddReminderDialog extends StatefulWidget {
  const _AddReminderDialog({
    required this.uid,
    required this.notificationService,
    required this.onSaved,
  });

  final String uid;
  final NotificationService notificationService;
  final VoidCallback onSaved;

  @override
  State<_AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<_AddReminderDialog> {
  final _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Selected days: 1=Mon … 7=Sun
  final Set<int> _selectedDays = {};
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSaving = false;

  static const List<String> _dayLabels = [
    'M', 'T', 'W', 'T', 'F', 'S', 'S'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Time picker
  // ---------------------------------------------------------------------------
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  String get _formattedTime {
    final h = _selectedTime.hour.toString().padLeft(2, '0');
    final m = _selectedTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final id =
        (DateTime.now().millisecondsSinceEpoch % 100000).toString();
    final reminder = NotificationModel(
      id: id,
      userId: widget.uid,
      title: _titleController.text.trim(),
      scheduledTime: _formattedTime,
      daysOfWeek: _selectedDays.toList()..sort(),
      isActive: true,
    );

    try {
      await widget.notificationService
          .saveReminder(reminder, widget.uid);
      await widget.notificationService.scheduleReminder(reminder);
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save reminder: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'New Reminder',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Reminder title',
                  hintText: 'e.g. Morning stretches',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Day selection
              const Text(
                'Days of week',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              _buildDaySelector(),
              const SizedBox(height: 20),

              // Time selector
              const Text(
                'Time',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: AppColors.textSecondary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _formattedTime,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit,
                          size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Day selector row
  // ---------------------------------------------------------------------------
  Widget _buildDaySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final day = index + 1; // 1=Mon … 7=Sun
        final isSelected = _selectedDays.contains(day);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedDays.remove(day);
              } else {
                _selectedDays.add(day);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.primary : Colors.grey.shade200,
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : Colors.grey.shade400,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                _dayLabels[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
