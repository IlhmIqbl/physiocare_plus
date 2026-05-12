import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:physiocare/models/exercise_model.dart';
import 'package:physiocare/utils/cloudinary_config.dart';

class AdminVideoUploadScreen extends StatefulWidget {
  const AdminVideoUploadScreen({super.key});

  @override
  State<AdminVideoUploadScreen> createState() =>
      _AdminVideoUploadScreenState();
}

class _AdminVideoUploadScreenState extends State<AdminVideoUploadScreen> {
  List<ExerciseModel> _exercises = [];
  bool _isLoading = true;

  // exerciseId → true while uploading
  final Map<String, bool> _uploading = {};

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

  Future<void> _pickAndUpload(ExerciseModel exercise) async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _uploading[exercise.id] = true);

    try {
      final publicId =
          '${CloudinaryConfig.folder}/${exercise.id}';
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/'
        '${CloudinaryConfig.cloudName}/video/upload',
      );

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
        ..fields['public_id'] = publicId
        ..files.add(await http.MultipartFile.fromPath('file', picked.path));

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      final json = jsonDecode(body) as Map<String, dynamic>;

      if (streamed.statusCode != 200) {
        final msg = (json['error'] as Map?)?['message'] ?? 'Upload failed';
        throw Exception(msg);
      }

      final secureUrl = json['secure_url'] as String;

      // Persist to Firestore
      await FirebaseFirestore.instance
          .collection('exercises')
          .doc(exercise.id)
          .update({'videoUrl': secureUrl});

      // Refresh local list
      final idx = _exercises.indexWhere((e) => e.id == exercise.id);
      if (idx != -1 && mounted) {
        setState(() {
          _exercises[idx] = _exercises[idx].copyWith(videoUrl: secureUrl);
          _uploading.remove(exercise.id);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video uploaded for "${exercise.title}"')),
        );
      }
    } catch (e) {
      setState(() => _uploading.remove(exercise.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Future<void> _clearVideo(ExerciseModel exercise) async {
    await FirebaseFirestore.instance
        .collection('exercises')
        .doc(exercise.id)
        .update({'videoUrl': ''});
    final idx = _exercises.indexWhere((e) => e.id == exercise.id);
    if (idx != -1 && mounted) {
      setState(() => _exercises[idx] = _exercises[idx].copyWith(videoUrl: ''));
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video URL cleared')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Exercise Videos'),
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
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final exercise = _exercises[index];
                    final isUploading =
                        _uploading[exercise.id] == true;
                    final hasVideo = exercise.videoUrl.isNotEmpty;

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Status icon
                            Icon(
                              hasVideo
                                  ? Icons.check_circle
                                  : Icons.videocam_off_outlined,
                              color:
                                  hasVideo ? Colors.green : Colors.grey,
                              size: 22,
                            ),
                            const SizedBox(width: 12),

                            // Exercise info
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_cap(exercise.bodyArea)} · ${_cap(exercise.difficulty)}',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),

                            // Action controls
                            if (isUploading)
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5),
                              )
                            else if (!hasVideo)
                              TextButton.icon(
                                icon: const Icon(Icons.upload, size: 18),
                                label: const Text('Upload'),
                                onPressed: () => _pickAndUpload(exercise),
                              )
                            else
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.swap_horiz,
                                        size: 18),
                                    label: const Text('Replace'),
                                    onPressed: () =>
                                        _pickAndUpload(exercise),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 20),
                                    tooltip: 'Remove video',
                                    onPressed: () =>
                                        _clearVideo(exercise),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
