import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiocare/models/exercise_model.dart';
import 'package:physiocare/models/exercise_step_model.dart';

class AdminVideoUploadScreen extends StatefulWidget {
  const AdminVideoUploadScreen({super.key});

  @override
  State<AdminVideoUploadScreen> createState() =>
      _AdminVideoUploadScreenState();
}

class _AdminVideoUploadScreenState extends State<AdminVideoUploadScreen> {
  List<ExerciseModel> _exercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('exercises').get();
      final exercises = snapshot.docs
          .map((d) => ExerciseModel.fromMap(d.data(), d.id))
          .toList()
        ..sort((a, b) {
          final area = a.bodyArea.compareTo(b.bodyArea);
          if (area != 0) return area;
          const order = {'easy': 0, 'medium': 1, 'hard': 2};
          return (order[a.difficulty] ?? 9)
              .compareTo(order[b.difficulty] ?? 9);
        });
      setState(() {
        _exercises = exercises;
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

  void _openEditor(ExerciseModel exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ExerciseEditorSheet(
        exercise: exercise,
        onSaved: (updated) {
          final idx = _exercises.indexWhere((e) => e.id == updated.id);
          if (idx != -1 && mounted) {
            setState(() => _exercises[idx] = updated);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Content'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExercises,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exercises.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No exercises found.'),
                      const SizedBox(height: 8),
                      const Text(
                        'Go back and tap "Re-seed Exercises" first.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _exercises.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final exercise = _exercises[index];
                    final hasVideo = exercise.videoUrl.isNotEmpty;

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        leading: Icon(
                          hasVideo
                              ? Icons.check_circle
                              : Icons.videocam_off_outlined,
                          color: hasVideo ? Colors.green : Colors.grey,
                        ),
                        title: Text(
                          exercise.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${_cap(exercise.bodyArea)} · ${_cap(exercise.difficulty)}'
                          ' · ${exercise.duration}s'
                          ' · ${exercise.steps.length} step(s)',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.edit_outlined,
                            color: Colors.teal),
                        onTap: () => _openEditor(exercise),
                      ),
                    );
                  },
                ),
    );
  }

  String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ---------------------------------------------------------------------------
// Editor bottom sheet
// ---------------------------------------------------------------------------

class _ExerciseEditorSheet extends StatefulWidget {
  const _ExerciseEditorSheet({
    required this.exercise,
    required this.onSaved,
  });

  final ExerciseModel exercise;
  final ValueChanged<ExerciseModel> onSaved;

  @override
  State<_ExerciseEditorSheet> createState() => _ExerciseEditorSheetState();
}

class _ExerciseEditorSheetState extends State<_ExerciseEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late final TextEditingController _videoUrlCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _durationCtrl;

  // Each entry is one step description controller
  final List<TextEditingController> _stepCtrls = [];

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _videoUrlCtrl = TextEditingController(text: e.videoUrl);
    _descCtrl = TextEditingController(text: e.description);
    _durationCtrl = TextEditingController(
        text: e.duration > 0 ? '${e.duration}' : '');

    if (e.steps.isNotEmpty) {
      for (final step in e.steps) {
        _stepCtrls.add(TextEditingController(text: step.description));
      }
    } else {
      _stepCtrls.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _videoUrlCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    for (final c in _stepCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addStep() {
    setState(() => _stepCtrls.add(TextEditingController()));
  }

  void _removeStep(int index) {
    if (_stepCtrls.length <= 1) return;
    setState(() {
      _stepCtrls[index].dispose();
      _stepCtrls.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final videoUrl = _videoUrlCtrl.text.trim();
      final description = _descCtrl.text.trim();
      final duration = int.tryParse(_durationCtrl.text.trim()) ?? 0;

      final steps = _stepCtrls
          .map((c) => c.text.trim())
          .where((desc) => desc.isNotEmpty)
          .map((desc) => ExerciseStep(
                description: desc,
                videoUrl: videoUrl,
                durationSeconds: duration > 0 && _stepCtrls.isNotEmpty
                    ? duration ~/ _stepCtrls.length
                    : 30,
              ))
          .toList();

      final updatedSteps =
          steps.map((s) => s.toMap()).toList();

      await FirebaseFirestore.instance
          .collection('exercises')
          .doc(widget.exercise.id)
          .update({
        'videoUrl': videoUrl,
        'description': description,
        'duration': duration,
        'steps': updatedSteps,
      });

      final updated = widget.exercise.copyWith(
        videoUrl: videoUrl,
        description: description,
        duration: duration,
        steps: steps,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('"${widget.exercise.title}" saved.')),
        );
        widget.onSaved(updated);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.exercise.title,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                '${_cap(widget.exercise.bodyArea)} · ${_cap(widget.exercise.difficulty)}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Video URL
              TextFormField(
                controller: _videoUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cloudinary Video URL',
                  hintText: 'https://res.cloudinary.com/...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.videocam_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Exercise Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Duration
              TextFormField(
                controller: _durationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Duration (seconds)',
                  hintText: 'e.g. 300 for 5 minutes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v != null &&
                      v.trim().isNotEmpty &&
                      int.tryParse(v.trim()) == null) {
                    return 'Enter a whole number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Steps
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Steps',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Step'),
                    onPressed: _addStep,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ..._stepCtrls.asMap().entries.map((entry) {
                final i = entry.key;
                final ctrl = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(top: 14, right: 8),
                        decoration: const BoxDecoration(
                          color: Colors.teal,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: ctrl,
                          decoration: const InputDecoration(
                            labelText: 'Step description',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red, size: 22),
                        onPressed: () => _removeStep(i),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),

              // Save button
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
                      : const Text('Save Changes',
                          style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
