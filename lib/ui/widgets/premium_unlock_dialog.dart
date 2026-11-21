import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/ad_service.dart';
import '../../core/auth_service.dart';
import '../../core/iap_service.dart';

class PremiumUnlockDialog extends StatefulWidget {
  final String controlKey;
  final String controlName;
  final String description;
  final VoidCallback onUnlocked;

  const PremiumUnlockDialog({
    super.key,
    required this.controlKey,
    required this.controlName,
    required this.description,
    required this.onUnlocked,
  });

  static Future<void> show({
    required BuildContext context,
    required String controlKey,
    required String controlName,
    required String description,
    required VoidCallback onUnlocked,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PremiumUnlockDialog(
        controlKey: controlKey,
        controlName: controlName,
        description: description,
        onUnlocked: onUnlocked,
      ),
    );
  }

  @override
  State<PremiumUnlockDialog> createState() => _PremiumUnlockDialogState();
}

class _PremiumUnlockDialogState extends State<PremiumUnlockDialog> {
  bool _isLoadingAd = false;
  bool _isPurchasing = false;

  Future<void> _watchAdToUnlock() async {
    setState(() => _isLoadingAd = true);
    final granted = await AdService.instance.showRewardedAdForControl(
      context: context,
      onUserEarnedReward: () {
        AuthService.instance.unlockControlForSession(widget.controlKey);
        widget.onUnlocked();
      },
    );

    if (mounted) {
      setState(() => _isLoadingAd = false);
      if (granted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF14243A),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppTheme.carNeonGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.controlName} unlocked for this session!',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  Future<void> _upgradeToVip() async {
    setState(() => _isPurchasing = true);
    final success = await IAPService.instance.purchasePackage('auramix_vip_lifetime');
    if (mounted) {
      setState(() => _isPurchasing = false);
      if (success) {
        widget.onUnlocked();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1B3D2F),
            content: Text('🎉 Welcome to AuraMix VIP! All controls permanently unlocked.'),
          ),
        );
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isPurchasing = true);
    final success = await IAPService.instance.restorePurchases();
    if (mounted) {
      setState(() => _isPurchasing = false);
      if (success) {
        widget.onUnlocked();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1B3D2F),
            content: Text('Purchases restored successfully! VIP activated.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No previous active VIP purchases found.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121424),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.carAmber.withAlpha(90), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.carAmber.withAlpha(50),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppTheme.neonPinkOrange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'PRO STUDIO CONTROL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.controlName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.description,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),

            // Card 1: Watch Rewarded Ad (Session Unlock)
            InkWell(
              onTap: _isLoadingAd ? null : _watchAdToUnlock,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF192238),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.neonCyan.withAlpha(90)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.neonCyan.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      child: _isLoadingAd
                          ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                          : const Icon(Icons.play_circle_fill_rounded, color: AppTheme.neonCyan, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Watch Ad · 1 Session Pass',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Unlock this control now. Free users watch again next session.',
                            style: TextStyle(fontSize: 11, color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.neonCyan),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Card 2: Upgrade to VIP (Unlimited)
            InkWell(
              onTap: _isPurchasing ? null : _upgradeToVip,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E1A47), Color(0xFF1E1632)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.carAmber.withAlpha(90)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.carAmber.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.all_inclusive_rounded, color: AppTheme.carAmber, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Get AuraMix VIP Pro',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Permanent unlock for all DPS controls & zero ads forever.',
                            style: TextStyle(fontSize: 11, color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.carAmber),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Restore Purchases & Cancel
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _isPurchasing ? null : _restorePurchases,
                  child: const Text(
                    'Restore Purchases',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Not Now',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
