import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/utils/app_constants.dart';

class TherapistProfileScreen extends StatelessWidget {
  const TherapistProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final name = auth.userModel?.name ?? 'Therapist';
    final email = auth.userModel?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'T';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              child: Text(initial,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(name,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Center(
            child: Text(email,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 14)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Chip(
              label: const Text('Physiotherapist'),
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout',
                style: TextStyle(color: Colors.red)),
            onTap: () async {
              await context.read<AppAuthProvider>().signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ],
      ),
    );
  }
}
