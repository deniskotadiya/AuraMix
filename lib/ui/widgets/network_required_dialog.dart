import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/ad_service.dart';
import '../../core/iap_service.dart';

class NetworkRequiredDialog extends StatefulWidget {
  final VoidCallback? onRetrySuccess;

  const NetworkRequiredDialog({super.key, this.onRetrySuccess});

  static bool _isShowing = false;

  static Future<void> show(BuildContext context, {VoidCallback? onRetrySuccess}) async {
    if (_isShowing) return;
    _isShowing = true;
    try {
      await showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withAlpha(190),
        builder: (ctx) => NetworkRequiredDialog(onRetrySuccess: onRetrySuccess),
      );
    } finally {
      _isShowing = false;
    }
  }

  @override
  State<NetworkRequiredDialog> createState() => _NetworkRequiredDialogState();
}

class _NetworkRequiredDialogState extends State<NetworkRequiredDialog> {
  bool _isChecking = false;
  bool _isPurchasing = false;

  Future<void> _checkConnection() async {
    setState(() => _isChecking = true);
    final isOnline = await AdService.instance.isNetworkAvailable();
    if (!mounted) return;
    setState(() => _isChecking = false);

    if (isOnline) {
      Navigator.of(context).pop();
      widget.onRetrySuccess?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0F3628),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.wifi, color: AppTheme.carNeonGreen),
              SizedBox(width: 10),
              Text(
                'Internet connection restored!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF36121D),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: AppTheme.neonPink),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Still offline. Please enable Wi-Fi or Cellular Data.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _upgradeToVip() async {
    setState(() => _isPurchasing = true);
    final success = await IAPService.instance.purchasePackage('auramix_vip_lifetime');
    if (!mounted) return;
    setState(() => _isPurchasing = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1B3D2F),
          behavior: SnackBarBehavior.floating,
          content: Text('🎉 VIP Activated! You can now use AuraMix 100% offline without ads.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withAlpha(245),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.carAmber.withAlpha(90), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.carAmber.withAlpha(45),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing Network Warning Icon
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0x55FFB703),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(color: AppTheme.carAmber.withAlpha(160), width: 1.5),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppTheme.carAmber,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),

            const Text(
              'NETWORK REQUIRED',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),

            const Text(
              'Free ad-supported playback requires an active internet connection to load sponsor messages.\n\nPlease turn on Wi-Fi or Mobile Data to continue, or upgrade to AuraMix VIP for complete offline playback with zero ads.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),

            // Upgrade to VIP Button (100% offline freedom)
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.cyanPurpleGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonCyan.withAlpha(60),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isPurchasing ? null : _upgradeToVip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isPurchasing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'UPGRADE TO VIP (OFFLINE PASS)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 10),

            // Retry Connection Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: _isChecking ? null : _checkConnection,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.carAmber.withAlpha(120), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: AppTheme.surfaceElevated.withAlpha(120),
                ),
                child: _isChecking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: AppTheme.carAmber, strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh_rounded, color: AppTheme.carAmber, size: 18),
                          SizedBox(width: 8),
                          Text(
                            "I'M CONNECTED (RETRY)",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: AppTheme.carAmber,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),

            // Dismiss Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Continue for now',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
