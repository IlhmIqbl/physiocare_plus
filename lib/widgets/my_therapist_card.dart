import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/utils/app_constants.dart';

class MyTherapistCard extends StatelessWidget {
  const MyTherapistCard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final therapistId = auth.userModel?.therapistId;

    if (therapistId == null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.medical_services_outlined, color: Colors.grey),
              SizedBox(width: 12),
              Text('No therapist assigned yet',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(therapistId).get(),
      builder: (context, snapshot) {
        String therapistName = 'Your Physiotherapist';
        if (snapshot.hasData && snapshot.data!.exists) {
          therapistName =
              (snapshot.data!.data() as Map<String, dynamic>)['name'] as String?
                  ?? therapistName;
        }
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: AppColors.surface,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.pushNamed(context, AppRoutes.therapistFeedback),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 20,
                    child: Icon(Icons.medical_services, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your Physiotherapist',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(therapistName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
