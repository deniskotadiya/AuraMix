import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'monetization_config.dart';

class IAPService {
  IAPService._();
  static final IAPService instance = IAPService._();

  bool _initialized = false;
  bool _isVip = false;

  final ValueNotifier<bool> vipStatusNotifier = ValueNotifier<bool>(MonetizationConfig.isPremium);

  bool get isVip => MonetizationConfig.isPremium || _isVip;

  Future<void> initialize() async {
    if (_initialized) return;

    // Load persisted local VIP status first
    final prefs = await SharedPreferences.getInstance();
    _isVip = MonetizationConfig.isPremium || (prefs.getBool('auramix_is_vip') ?? false);
    vipStatusNotifier.value = isVip;

    try {
      // If RevenueCat key is configured, initialize RevenueCat
      if (MonetizationConfig.revenueCatAndroidPublicSdkKey != 'goog_REPLACE_WITH_YOUR_KEY') {
        await Purchases.setLogLevel(LogLevel.debug);
        PurchasesConfiguration configuration = PurchasesConfiguration(
          MonetizationConfig.revenueCatAndroidPublicSdkKey,
        );
        await Purchases.configure(configuration);
        _initialized = true;
        await checkSubscriptionStatus();
      }
    } catch (e) {
      debugPrint('[IAPService] Purchases config error: $e');
    }
  }

  Future<void> checkSubscriptionStatus() async {
    try {
      if (!_initialized) return;
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      final hasActiveVip = customerInfo.entitlements.active.containsKey('vip_access') ||
          customerInfo.activeSubscriptions.isNotEmpty;
      await setVip(hasActiveVip);
    } catch (e) {
      debugPrint('[IAPService] checkSubscriptionStatus error: $e');
    }
  }

  Future<bool> purchasePackage(String packageId) async {
    try {
      if (_initialized) {
        // Find offering and purchase
        Offerings offerings = await Purchases.getOfferings();
        Package? packageToBuy;
        if (offerings.current != null) {
          for (var p in offerings.current!.availablePackages) {
            if (p.identifier == packageId) {
              packageToBuy = p;
              break;
            }
          }
        }

        if (packageToBuy != null) {
          CustomerInfo customerInfo = await Purchases.purchasePackage(packageToBuy);
          final hasActive = customerInfo.entitlements.active.containsKey('vip_access') ||
              customerInfo.activeSubscriptions.isNotEmpty;
          await setVip(hasActive);
          return hasActive;
        }
      }

      // Demo/Fallback purchase mode for local testing before App Store / Play Store credentials
      await setVip(true);
      return true;
    } catch (e) {
      debugPrint('[IAPService] Purchase error: $e');
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      if (_initialized) {
        CustomerInfo customerInfo = await Purchases.restorePurchases();
        final hasActive = customerInfo.entitlements.active.containsKey('vip_access') ||
            customerInfo.activeSubscriptions.isNotEmpty;
        await setVip(hasActive);
        return hasActive;
      } else {
        // Fallback restore check from local prefs
        final prefs = await SharedPreferences.getInstance();
        final restored = prefs.getBool('auramix_is_vip') ?? false;
        await setVip(restored);
        return restored;
      }
    } catch (e) {
      debugPrint('[IAPService] Restore error: $e');
      return false;
    }
  }

  Future<void> setVip(bool vip) async {
    _isVip = vip;
    vipStatusNotifier.value = isVip;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auramix_is_vip', vip);
  }
}
