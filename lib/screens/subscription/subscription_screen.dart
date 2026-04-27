import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/providers/subscription_provider.dart';
import 'package:physiocare/utils/app_constants.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isUpgrading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid =
          context.read<AppAuthProvider>().userModel?.id ?? '';
      if (uid.isNotEmpty) {
        final subscriptionProvider = context.read<SubscriptionProvider>();
        subscriptionProvider.loadSubscription(uid);
        subscriptionProvider.listenToSubscription(uid);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Feature comparison data
  // ---------------------------------------------------------------------------
  static const List<_FeatureRow> _features = [
    _FeatureRow('Exercise Library', true, true),
    _FeatureRow('Basic Progress', true, true),
    _FeatureRow('Recovery Plans', true, true),
    _FeatureRow('Advanced Analytics', false, true),
    _FeatureRow('Progress Export', false, true),
    _FeatureRow('Therapist Tips', false, true),
    _FeatureRow('Smart Reminders', false, true),
    _FeatureRow('Priority Support', false, true),
  ];

  // ---------------------------------------------------------------------------
  // Upgrade flow
  // ---------------------------------------------------------------------------
  Future<void> _handleUpgrade(BuildContext context, String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: const Text(
          'You are about to upgrade to PhysioCare+ Premium.\n\n'
          'RM 9.90 / month will be charged to your account.\n\n'
          'Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isUpgrading = true);

    try {
      await context.read<SubscriptionProvider>().upgradeToPremium(uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully upgraded to Premium!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upgrade failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpgrading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final authProvider = context.watch<AppAuthProvider>();
    final uid = authProvider.userModel?.id ?? '';
    final isPremium = subscriptionProvider.isPremium;
    final subscription = subscriptionProvider.subscription;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        backgroundColor: AppColors.primary,
      ),
      body: subscriptionProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Current plan banner ──────────────────────────────────
                  _buildPlanBanner(isPremium, subscription?.endDate),
                  const SizedBox(height: 24),

                  // ── Compare plans heading ────────────────────────────────
                  const Text(
                    'Compare Plans',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Feature comparison table ─────────────────────────────
                  _buildFeatureTable(),
                  const SizedBox(height: 32),

                  // ── Upgrade card / premium message ───────────────────────
                  if (!isPremium)
                    _buildUpgradeCard(context, uid)
                  else
                    _buildPremiumMessage(),
                ],
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Plan banner
  // ---------------------------------------------------------------------------
  Widget _buildPlanBanner(bool isPremium, DateTime? endDate) {
    final Color bannerColor =
        isPremium ? AppColors.primary : Colors.grey.shade600;

    String? formattedEnd;
    if (isPremium && endDate != null) {
      formattedEnd = DateFormat('d MMM yyyy').format(endDate);
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: bannerColor,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            Icon(
              isPremium ? Icons.star : Icons.star_border,
              color: isPremium ? Colors.amber : Colors.grey.shade300,
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPremium ? 'Premium' : 'Free Plan',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isPremium && formattedEnd != null)
                    Text(
                      'Active until $formattedEnd',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 13,
                      ),
                    )
                  else
                    const Text(
                      'Upgrade to unlock all features',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Feature table
  // ---------------------------------------------------------------------------
  Widget _buildFeatureTable() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Header row
            Container(
              color: AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: const [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Feature',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Free',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Premium',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Data rows
            ..._features.asMap().entries.map((entry) {
              final index = entry.key;
              final feature = entry.value;
              final isEven = index % 2 == 0;
              return _buildFeatureDataRow(
                feature,
                isEven ? Colors.white : AppColors.surface.withOpacity(0.5),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureDataRow(_FeatureRow feature, Color bgColor) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              feature.name,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: feature.freemium
                  ? const Icon(Icons.check, color: Colors.green, size: 18)
                  : const Icon(Icons.close, color: Colors.red, size: 18),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: feature.premium
                  ? const Icon(Icons.check, color: Colors.green, size: 18)
                  : const Icon(Icons.close, color: Colors.red, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Upgrade card
  // ---------------------------------------------------------------------------
  Widget _buildUpgradeCard(BuildContext context, String uid) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.amber.shade600, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PhysioCare+ Premium',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'RM 9.90 / month  ·  RM 99 / year',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: _isUpgrading
                    ? null
                    : () => _handleUpgrade(context, uid),
                child: _isUpgrading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Upgrade to Premium'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Premium message
  // ---------------------------------------------------------------------------
  Widget _buildPremiumMessage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'You have full access to all features!',
          style: TextStyle(
            color: Colors.green,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Simple data class for feature rows
// ---------------------------------------------------------------------------
class _FeatureRow {
  const _FeatureRow(this.name, this.freemium, this.premium);
  final String name;
  final bool freemium;
  final bool premium;
}
