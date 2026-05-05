import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiocare/models/exercise_model.dart';
import 'package:physiocare/services/exercise_service.dart';
import 'package:physiocare/services/firestore_service.dart';

class AdminExercisesScreen extends StatefulWidget {
  const AdminExercisesScreen({super.key});

  @override
  State<AdminExercisesScreen> createState() => _AdminExercisesScreenState();
}

class _AdminExercisesScreenState extends State<AdminExercisesScreen> {
  final _firestoreService = FirestoreService();
  final _exerciseService = ExerciseService();

  List<ExerciseModel> _exercises = [];
  bool _isLoading = false;

  static const List<String> _bodyAreas = [
    'neck',
    'shoulder',
    'back',
    'hip',
    'knee',
    'ankle',
  ];

  static const List<String> _difficulties = ['easy', 'medium', 'hard'];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestoreService.getCollection('exercises');
      setState(() {
        _exercises = snapshot.docs
            .map((doc) => ExerciseModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exercises: $e')),
        );
      }
    }
  }

  Future<void> _deleteExercise(ExerciseModel exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exercise'),
        content:
            Text('Are you sure you want to deactivate "${exercise.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _exerciseService.deleteExercise(exercise.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${exercise.title}" deactivated')),
        );
      }
      await _loadExercises();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting exercise: $e')),
        );
      }
    }
  }

  void _showExerciseForm(BuildContext context, ExerciseModel? exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ExerciseFormSheet(
        exercise: exercise,
        bodyAreas: _bodyAreas,
        difficulties: _difficulties,
        exerciseService: _exerciseService,
        onSaved: _loadExercises,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Exercises'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExercises,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        onPressed: () => _showExerciseForm(context, null),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exercises.isEmpty
              ? const Center(child: Text('No exercises found.'))
              : ListView.builder(
                  itemCount: _exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = _exercises[index];
                    return ListTile(
                      leading: exercise.thumbnailUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                exercise.thumbnailUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _e, _s) => const Icon(
                                    Icons.fitness_center,
                                    size: 40,
                                    color: Colors.teal),
                              ),
                            )
                          : const Icon(Icons.fitness_center,
                              size: 40, color: Colors.teal),
                      title: Text(
                        exercise.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: exercise.isActive ? null : Colors.grey,
                        ),
                      ),
                      subtitle: Text(
                        '${exercise.bodyArea} • ${exercise.difficulty}'
                        '${exercise.isActive ? '' : ' [INACTIVE]'}',
                        style: TextStyle(
                          color: exercise.isActive ? null : Colors.grey,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: Colors.teal),
                            tooltip: 'Edit',
                            onPressed: () =>
                                _showExerciseForm(context, exercise),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            tooltip: 'Delete',
                            onPressed: () => _deleteExercise(exercise),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise form bottom sheet
// ---------------------------------------------------------------------------

class _ExerciseFormSheet extends StatefulWidget {
  const _ExerciseFormSheet({
    required this.exercise,
    required this.bodyAreas,
    required this.difficulties,
    required this.exerciseService,
    required this.onSaved,
  });

  final ExerciseModel? exercise;
  final List<String> bodyAreas;
  final List<String> difficulties;
  final ExerciseService exerciseService;
  final VoidCallback onSaved;

  @override
  State<_ExerciseFormSheet> createState() => _ExerciseFormSheetState();
}

class _ExerciseFormSheetState extends State<_ExerciseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _videoUrlCtrl;
  late final TextEditingController _thumbnailUrlCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _stepsCtrl;

  late String _bodyArea;
  late String _difficulty;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _videoUrlCtrl = TextEditingController(text: e?.videoUrl ?? '');
    _thumbnailUrlCtrl = TextEditingController(text: e?.thumbnailUrl ?? '');
    _durationCtrl =
        TextEditingController(text: e != null ? '${e.duration}' : '');
    _stepsCtrl = TextEditingController(
        text: e != null ? e.steps.join(', ') : '');
    _bodyArea = e?.bodyArea ?? widget.bodyAreas.first;
    _difficulty = e?.difficulty ?? widget.difficulties.first;
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _videoUrlCtrl.dispose();
    _thumbnailUrlCtrl.dispose();
    _durationCtrl.dispose();
    _stepsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final steps = _stepsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final duration = int.tryParse(_durationCtrl.text.trim()) ?? 0;
      final now = DateTime.now();

      if (widget.exercise == null) {
        // Add new
        final docRef =
            await FirebaseFirestore.instance.collection('exercises').add({});
        final newExercise = ExerciseModel(
          id: docRef.id,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          bodyArea: _bodyArea,
          difficulty: _difficulty,
          duration: duration,
          videoUrl: _videoUrlCtrl.text.trim(),
          thumbnailUrl: _thumbnailUrlCtrl.text.trim(),
          targetPainTypes: const [],
          steps: steps,
          isActive: _isActive,
          createdAt: now,
        );
        await widget.exerciseService.addExercise(newExercise);
      } else {
        // Update existing
        final updated = widget.exercise!.copyWith(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          bodyArea: _bodyArea,
          difficulty: _difficulty,
          duration: duration,
          videoUrl: _videoUrlCtrl.text.trim(),
          thumbnailUrl: _thumbnailUrlCtrl.text.trim(),
          steps: steps,
          isActive: _isActive,
        );
        await widget.exerciseService.updateExercise(updated);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.exercise == null
                  ? 'Exercise added'
                  : 'Exercise updated')),
        );
      }
      widget.onSaved();
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving exercise: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.exercise != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    isEditing ? 'Edit Exercise' : 'Add Exercise',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _videoUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Video URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _thumbnailUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Thumbnail URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _bodyArea,
                      decoration: const InputDecoration(
                        labelText: 'Body Area',
                        border: OutlineInputBorder(),
                      ),
                      items: widget.bodyAreas
                          .map((a) => DropdownMenuItem(
                              value: a,
                              child: Text(
                                  a[0].toUpperCase() + a.substring(1))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _bodyArea = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _difficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficulty',
                        border: OutlineInputBorder(),
                      ),
                      items: widget.difficulties
                          .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(
                                  d[0].toUpperCase() + d.substring(1))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _difficulty = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Duration (seconds)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (int.tryParse(v.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stepsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Steps (comma-separated)',
                  hintText: 'Stand upright, Bend knee, Hold for 5s',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                subtitle: const Text('Inactive exercises won\'t appear to users'),
                value: _isActive,
                activeThumbColor: Colors.teal,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Update Exercise' : 'Add Exercise'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
