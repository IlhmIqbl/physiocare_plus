import 'package:flutter/material.dart';
import 'package:physiocare/models/user_model.dart';
import 'package:physiocare/therapist/services/therapist_service.dart';
import 'package:physiocare/utils/app_constants.dart';

class ManageTherapistsScreen extends StatefulWidget {
  const ManageTherapistsScreen({super.key});

  @override
  State<ManageTherapistsScreen> createState() =>
      _ManageTherapistsScreenState();
}

class _ManageTherapistsScreenState extends State<ManageTherapistsScreen> {
  final _service = TherapistService();
  List<UserModel> _therapists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final therapists = await _service.getAllTherapists();
      setState(() {
        _therapists = therapists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading therapists: $e')));
      }
    }
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Therapist Account'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Valid email required' : null,
              ),
              TextFormField(
                controller: passCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Min 6 characters' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.cancel)),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                await _service.createTherapistAccount(
                    nameCtrl.text.trim(),
                    emailCtrl.text.trim(),
                    passCtrl.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Therapist account created')));
                  _load();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Therapists'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('New Therapist', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _therapists.isEmpty
              ? const Center(child: Text('No therapists yet'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _therapists.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, i) {
                    final t = _therapists[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: Text(
                          t.name.isNotEmpty ? t.name[0].toUpperCase() : 'T',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(t.name),
                      subtitle: Text(t.email),
                    );
                  },
                ),
    );
  }
}
