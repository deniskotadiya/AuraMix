import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/auth_service.dart';
import '../../core/iap_service.dart';
import '../../core/monetization_config.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final VoidCallback onSignOut;

  const ProfileSettingsScreen({super.key, required this.onSignOut});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _isPurchasing = false;

  Future<void> _buyVip(String planId) async {
    setState(() => _isPurchasing = true);
    final success = await IAPService.instance.purchasePackage(planId);
    if (mounted) {
      setState(() => _isPurchasing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success ? const Color(0xFF1B3D2F) : Colors.redAccent,
          content: Text(success ? '🎉 VIP Pro activated successfully!' : 'Purchase cancelled or failed'),
        ),
      );
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isPurchasing = true);
    final success = await IAPService.instance.restorePurchases();
    if (mounted) {
      setState(() => _isPurchasing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ Purchases restored! VIP activated.' : 'No active subscriptions found.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AuthService.instance.currentUserNotifier,
        IAPService.instance.vipStatusNotifier,
      ]),
      builder: (context, _) {
        final user = AuthService.instance.currentUser;
        final isVip = IAPService.instance.isVip;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Pilot Profile & VIP'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Avatar & Information Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.neonBoxDecoration(
                    glowColor: isVip ? AppTheme.carAmber : AppTheme.neonCyan,
                    surfaceColor: const Color(0xFF131526),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isVip ? AppTheme.neonPinkOrange : AppTheme.cyanPurpleGradient,
                          boxShadow: [
                            BoxShadow(
                              color: isVip ? AppTheme.carAmber.withAlpha(90) : AppTheme.neonCyan.withAlpha(90),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person_rounded, size: 36, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user?.displayName ?? 'Audiophile Pilot',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isVip ? AppTheme.carAmber : Colors.white24,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isVip ? 'VIP PRO' : 'FREE TIER',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: isVip ? Colors.black : Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'driver@auramix.app',
                              style: const TextStyle(fontSize: 12, color: Colors.white60),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${user?.uid ?? "local_pilot"}',
                              style: const TextStyle(fontSize: 10, color: AppTheme.neonCyan),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // VIP Pro Subscription Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2C1947), Color(0xFF1B1430), Color(0xFF101222)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.carAmber.withAlpha(100), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.workspace_premium, color: AppTheme.carAmber, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'AuraMix VIP Studio',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                          if (isVip)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.carNeonGreen.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.carNeonGreen),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.carNeonGreen),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '• 100% Ad-Free Listening (No Banners or Interstitials)\n• Unlimited Studio Controls: Tube Warmth, 3D Spatializer & Dynamic Compressor\n• Create Unlimited Custom Presets with Community Sharing',
                        style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
                      ),
                      const SizedBox(height: 16),

                      if (!isVip) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _PlanOptionButton(
                                title: 'Monthly',
                                price: '\$2.99/mo',
                                isLoading: _isPurchasing,
                                onTap: () => _buyVip(MonetizationConfig.iapMonthlyId),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _PlanOptionButton(
                                title: 'Lifetime',
                                price: '\$19.99',
                                isPopular: true,
                                isLoading: _isPurchasing,
                                onTap: () => _buyVip(MonetizationConfig.iapLifetimeId),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        OutlinedButton(
                          onPressed: () => IAPService.instance.setVip(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white60,
                            side: const BorderSide(color: Colors.white24),
                          ),
                          child: const Text('Cancel / Reset VIP (Demo Toggle)'),
                        ),
                      ],

                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: _isPurchasing ? null : _restorePurchases,
                          child: const Text(
                            'Restore App Store / Play Store Purchases',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Rewarded Ad Session Unlocked Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassBoxDecoration(radius: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.video_library_outlined, size: 18, color: AppTheme.neonCyan),
                          SizedBox(width: 8),
                          Text(
                            'Rewarded Ad Session Unlocks',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Controls unlocked by watching ads are valid for this current session. Free users watch ads per session or upgrade to VIP.',
                        style: TextStyle(fontSize: 11, color: Colors.white54, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _UnlockStatusChip(
                            label: 'Tube Amp Warmth',
                            isUnlocked: AuthService.instance.isControlUnlocked(MonetizationConfig.controlTubeWarmth),
                          ),
                          _UnlockStatusChip(
                            label: 'Dynamic Compressor',
                            isUnlocked: AuthService.instance.isControlUnlocked(MonetizationConfig.controlCompressor),
                          ),
                          _UnlockStatusChip(
                            label: '3D Surround',
                            isUnlocked: AuthService.instance.isControlUnlocked(MonetizationConfig.controlSurround3D),
                          ),
                          _UnlockStatusChip(
                            label: 'Cathedral Reverb',
                            isUnlocked: AuthService.instance.isControlUnlocked(MonetizationConfig.controlReverbCathedral),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Configuration Checklist Quick Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassBoxDecoration(radius: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.developer_mode_rounded, size: 18, color: AppTheme.carAmber),
                          SizedBox(width: 8),
                          Text(
                            'Developer & Monetization Status',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• App-wide isPremium Flag: ${MonetizationConfig.isPremium ? "TRUE (Full Access Unlocked)" : "false"}\n• AdMob Test Ads: ${MonetizationConfig.useTestAds ? "Active (Safe testing)" : "Production IDs"}\n• Firebase Integration: ${MonetizationConfig.firebaseEnabled ? "Enabled" : "Demo local persistence (toggle in MonetizationConfig)"}\n• Audio Engine: just_audio + DSP multi-band EQ\n• Flutter SDK: 3.47.x (Quail compatible)',
                        style: const TextStyle(fontSize: 11, color: Colors.white60, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Sign Out Button
                OutlinedButton.icon(
                  onPressed: () {
                    AuthService.instance.signOut();
                    widget.onSignOut();
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppTheme.neonPink),
                  label: const Text('SIGN OUT OF COCKPIT', style: TextStyle(color: AppTheme.neonPink, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.neonPink.withAlpha(90)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlanOptionButton extends StatelessWidget {
  final String title;
  final String price;
  final bool isPopular;
  final bool isLoading;
  final VoidCallback onTap;

  const _PlanOptionButton({
    required this.title,
    required this.price,
    this.isPopular = false,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isPopular ? AppTheme.carAmber.withAlpha(35) : Colors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPopular ? AppTheme.carAmber : Colors.white24,
            width: isPopular ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            if (isPopular)
              const Text(
                'BEST VALUE',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.carAmber),
              ),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              price,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: isPopular ? AppTheme.carAmber : AppTheme.neonCyan,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnlockStatusChip extends StatelessWidget {
  final String label;
  final bool isUnlocked;

  const _UnlockStatusChip({
    required this.label,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isUnlocked ? AppTheme.carNeonGreen.withAlpha(25) : Colors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnlocked ? AppTheme.carNeonGreen.withAlpha(80) : Colors.white12,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUnlocked ? Icons.check_circle_outline : Icons.lock_outline,
            size: 13,
            color: isUnlocked ? AppTheme.carNeonGreen : Colors.white38,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? AppTheme.carNeonGreen : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
