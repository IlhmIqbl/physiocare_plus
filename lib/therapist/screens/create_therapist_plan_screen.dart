import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/models/exercise_model.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/providers/exercise_provider.dart';
import 'package:physiocare/therapist/models/therapist_plan_model.dart';
import 'package:physiocare/therapist/providers/therapist_provider.dart';
import 'package:physiocare/utils/app_constants.dart';

class CreateTherapistPlanScreen extends StatefulWidget {
  const CreateTherapistPlanScreen({super.key, this.existingPlan});
  final TherapistPlanModel? existingPlan;

  @override
  State<CreateTherapistPlanScreen> createState() =>
      _CreateTherapistPlanScreenState();
}

class _CreateTherapistPlanScreenState
    extends State<CreateTherapistPlanScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final List<_PlanExerciseEntry> _entries = [];

  bool get _isEditing => widget.existingPlan != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExerciseProvider>().loadExercises();
    });
    if (_isEditing) {
      final plan = widget.existingPlan!;
      _titleCtrl.text = plan.title;
      _descCtrl.text = plan.description;
      for (final ex in plan.exercises) {
        _entries.add(_PlanExerciseEntry(
          exerciseId: ex.exerciseId,
          sets: ex.sets,
          reps: ex.reps,
          durationSecs: ex.durationSecs,
        ));
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _addExercise(ExerciseModel exercise) {
    setState(() {
      _entries.add(_PlanExerciseEntry(
        exerciseId: exercise.id,
        sets: 3,
        reps: 10,
        durationSecs: 30,
      ));
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one exercise')));
      return;
    }
    final auth = context.read<AppAuthProvider>();
    final provider = context.read<TherapistProvider>();
    final exercises = _entries
        .map((e) => TherapistPlanExercise(
              exerciseId: e.exerciseId,
              sets: e.sets,
              reps: e.reps,
              durationSecs: e.durationSecs,
            ))
        .toList();

    if (_isEditing) {
      final updated = widget.existingPlan!.copyWith(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        exercises: exercises,
      );
      await provider.updatePlan(updated);
    } else {
      final plan = TherapistPlanModel(
        id: '',
        therapistId: auth.userModel?.id ?? '',
        patientId: provider.selectedPatient?.id ?? '',
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        exercises: exercises,
        createdAt: DateTime.now(),
        active: true,
      );
      await provider.createPlan(plan);
    }
    if (mounted) Navigator.pop(context);
  }

  void _showExercisePicker(ExerciseProvider exerciseProvider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        itemCount: exerciseProvider.exercises.length,
        itemBuilder: (context, i) {
          final ex = exerciseProvider.exercises[i];
          return ListTile(
            title: Text(ex.title),
            subtitle: Text(ex.bodyArea),
            onTap: () {
              _addExercise(ex);
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exerciseProvider = context.watch<ExerciseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Plan' : 'Create Plan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Plan Title', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Description', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Exercises',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  onPressed: () => _showExercisePicker(exerciseProvider),
                ),
              ],
            ),
            if (_entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No exercises added yet',
                    style: TextStyle(color: Colors.grey)),
              )
            else
              ..._entries.asMap().entries.map((entry) {
                final idx = entry.key;
                final e = entry.value;
                return _ExerciseEntryTile(
                  entry: e,
                  exerciseName: exerciseProvider.exercises
                      .where((ex) => ex.id == e.exerciseId)
                      .map((ex) => ex.title)
                      .firstOrNull ?? e.exerciseId,
                  onRemove: () => setState(() => _entries.removeAt(idx)),
                  onChanged: () => setState(() {}),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _PlanExerciseEntry {
  String exerciseId;
  int sets;
  int reps;
  int durationSecs;

  _PlanExerciseEntry({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.durationSecs,
  });
}

class _ExerciseEntryTile extends StatelessWidget {
  const _ExerciseEntryTile({
    required this.entry,
    required this.exerciseName,
    required this.onRemove,
    required this.onChanged,
  });

  final _PlanExerciseEntry entry;
  final String exerciseName;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(exerciseName,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onRemove),
              ],
            ),
            Row(
              children: [
                _CounterField(
                  label: 'Sets',
                  value: entry.sets,
                  onDecrement: () {
                    if (entry.sets > 1) {
                      entry.sets--;
                      onChanged();
                    }
                  },
                  onIncrement: () {
                    entry.sets++;
                    onChanged();
                  },
                ),
                const SizedBox(width: 16),
                _CounterField(
                  label: 'Reps',
                  value: entry.reps,
                  onDecrement: () {
                    if (entry.reps > 1) {
                      entry.reps--;
                      onChanged();
                    }
                  },
                  onIncrement: () {
                    entry.reps++;
                    onChanged();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterField extends StatelessWidget {
  const _CounterField({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: onDecrement,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints()),
        Text('$value',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: onIncrement,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints()),
      ],
    );
  }
}
