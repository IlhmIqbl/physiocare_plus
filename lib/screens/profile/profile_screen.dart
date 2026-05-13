import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/providers/progress_provider.dart';
import 'package:physiocare/services/firestore_service.dart';
import 'package:physiocare/utils/app_constants.dart';
import 'package:physiocare/widgets/pain_slider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  double _painSeverity = 5.0;
  List<String> _selectedBodyAreas = [];
  bool _isEditing = false;
  bool _isSaving = false;
  Uint8List? _imageBytes;

  static const List<String> _bodyAreas = [
    'shoulder',
    'lower_back',
    'knee',
    'hip',
    'neck',
    'ankle',
  ];

  String _formatBodyAreaLabel(String area) {
    return area
        .split('_')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _populateFromModel();
    });
  }

  void _populateFromModel() {
    final userModel = context.read<AppAuthProvider>().userModel;
    if (userModel != null) {
      setState(() {
        _nameController.text = userModel.name;
        _painSeverity = (userModel.painSeverity).toDouble();
        _selectedBodyAreas = List<String>.from(userModel.bodyFocusAreas);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = context.read<AppAuthProvider>();
    final uid = authProvider.userModel?.id;
    if (uid == null) return;

    setState(() => _isSaving = true);

    try {
      String? photoUrl;

      if (_imageBytes != null) {
        final ref = FirebaseStorage.instance.ref('profile_photos/$uid');
        await ref.putData(_imageBytes!, SettableMetadata(contentType: 'image/jpeg'));
        photoUrl = await ref.getDownloadURL();
      }

      final Map<String, dynamic> updateData = {
        'name': name,
        'painSeverity': _painSeverity.round(),
        'bodyFocusAreas': _selectedBodyAreas,
      };

      if (photoUrl != null) {
        updateData['photoUrl'] = photoUrl;
      }

      await FirestoreService().updateDoc('users', uid, updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully.'),
            backgroundColor: Color(0xFF00897B),
          ),
        );
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  Color _severityColor(double value) {
    if (value <= 3) return Colors.green;
    if (value <= 6) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final userModel = authProvider.userModel;
    final name = userModel?.name ?? '';
    final email = userModel?.email ?? '';
    final photoUrl = userModel?.photoUrl;
    final userType = userModel?.userType ?? 'freemium';
    final isPremium = userType == 'premium';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: _isSaving
                ? null
                : () {
                    if (_isEditing) {
                      _saveProfile();
                    } else {
                      setState(() => _isEditing = true);
                    }
                  },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---- Avatar section ----
                Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFF00897B),
                          backgroundImage: _imageBytes != null
                              ? MemoryImage(_imageBytes!) as ImageProvider
                              : (photoUrl != null
                                  ? NetworkImage(photoUrl) as ImageProvider
                                  : null),
                          child: (_imageBytes == null && photoUrl == null)
                              ? Text(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                    if (_isEditing) ...[
                      IconButton(
                        icon: const Icon(Icons.camera_alt,
                            color: Color(0xFF00897B)),
                        onPressed: _pickImage,
                        tooltip: 'Change photo',
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (!_isEditing) ...[
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(
                          userType.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: isPremium
                            ? const Color(0xFFFFF9C4)
                            : const Color(0xFFE0F2F1),
                        side: BorderSide(
                          color: isPremium
                              ? const Color(0xFFF9A825)
                              : const Color(0xFF00897B),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // ---- Name field (edit mode only) ----
                if (_isEditing) ...[
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ---- Body Focus Areas ----
                const Text(
                  'Body Focus Areas',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _bodyAreas.map((area) {
                    final isSelected = _selectedBodyAreas.contains(area);
                    return FilterChip(
                      label: Text(_formatBodyAreaLabel(area)),
                      selected: isSelected,
                      selectedColor: const Color(0xFFE0F2F1),
                      checkmarkColor: const Color(0xFF00897B),
                      onSelected: _isEditing
                          ? (bool value) {
                              setState(() {
                                if (value) {
                                  _selectedBodyAreas.add(area);
                                } else {
                                  _selectedBodyAreas.remove(area);
                                }
                              });
                            }
                          : null,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // ---- Pain Severity ----
                const Text(
                  'Default Pain Severity',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                if (_isEditing) ...[
                  PainSlider(
                    value: _painSeverity,
                    onChanged: (value) {
                      setState(() => _painSeverity = value);
                    },
                    label: 'Pain Severity',
                  ),
                ] else ...[
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _severityColor(_painSeverity),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_painSeverity.round()}/10',
                        style: TextStyle(
                          fontSize: 16,
                          color: _severityColor(_painSeverity),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),

                // ---- Account section ----
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.email_outlined,
                            color: Color(0xFF00897B)),
                        title: const Text('Email'),
                        subtitle: Text(email),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.account_circle_outlined,
                            color: Color(0xFF00897B)),
                        title: const Text('Account Type'),
                        subtitle: Text(userType),
                        trailing: isPremium
                            ? const Icon(Icons.star, color: Color(0xFFF9A825))
                            : null,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.card_membership_outlined,
                            color: Color(0xFF00897B)),
                        title: const Text('Subscription'),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey),
                        onTap: () {
                          Navigator.of(context)
                              .pushNamed(AppRoutes.subscription);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ---- Admin Panel button (admin only) ----
                if (userType == 'admin') ...[
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.adminDashboard),
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Go to Admin Panel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ---- Sign Out button ----
                OutlinedButton.icon(
                  onPressed: () async {
                    final progress = context.read<ProgressProvider>();
                    final auth = context.read<AppAuthProvider>();
                    await progress.clearProgress();
                    await auth.signOut();
                    if (context.mounted) {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (_isSaving)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                backgroundColor: Color(0xFFE0F2F1),
                color: Color(0xFF00897B),
              ),
            ),
        ],
      ),
    );
  }
}
