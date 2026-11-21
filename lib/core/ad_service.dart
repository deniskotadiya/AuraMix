import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../main.dart';
import '../ui/widgets/network_required_dialog.dart';
import 'monetization_config.dart';
import 'iap_service.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;
  RewardedAd? _rewardedAd;
  bool _isLoadingRewarded = false;
  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitial = false;
  DateTime? _lastInterstitialShown;

  // Action counter: Trigger ads every 3 to 5 audio or controller changes
  int _actionCount = 0;
  static const int actionThreshold = 4; // Midpoint between 3 and 5
  DateTime? _lastActionCountedTime;

  int get currentActionCount => _actionCount;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      loadRewardedAd();
      loadInterstitialAd();
    } catch (e) {
      debugPrint('[AdService] MobileAds init error: $e');
    }
  }

  /// Check whether real internet connectivity is currently accessible
  Future<bool> isNetworkAvailable() async {
    try {
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    try {
      final fallback = await InternetAddress.lookup('1.1.1.1')
          .timeout(const Duration(seconds: 2));
      return fallback.isNotEmpty && fallback[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Increments interaction counter when audio or controller changes.
  /// If threshold reached (every 4 changes), triggers ad if online, or network popup if offline.
  void recordUserAction({BuildContext? context, String reason = 'User Action'}) {
    // Premium VIP users never see ads and have 100% unrestricted offline freedom
    if (IAPService.instance.isVip) return;

    final now = DateTime.now();
    if (_lastActionCountedTime != null &&
        now.difference(_lastActionCountedTime!).inMilliseconds < 400) {
      // Throttle rapid repeated triggers (e.g. fast continuous dragging)
      return;
    }
    _lastActionCountedTime = now;
    _actionCount++;
    debugPrint('[AdService] Action recorded: $reason (Count: $_actionCount / $actionThreshold)');

    if (_actionCount >= actionThreshold) {
      _actionCount = 0;
      triggerAdOrNetworkPrompt(context: context);
    }
  }

  /// Evaluates network condition when it is time to show an ad.
  Future<void> triggerAdOrNetworkPrompt({BuildContext? context}) async {
    if (IAPService.instance.isVip) return;

    final hasNetwork = await isNetworkAvailable();
    final ctx = AuraMixApp.navigatorKey.currentContext;

    if (!hasNetwork) {
      debugPrint('[AdService] Free user is offline when ad is due. Showing network popup.');
      if (ctx != null && ctx.mounted) {
        NetworkRequiredDialog.show(ctx);
      }
      return;
    }

    debugPrint('[AdService] Network online. Showing interstitial ad.');
    await showInterstitialAdIfAllowed();
  }

  void loadInterstitialAd() {
    if (_isLoadingInterstitial || _interstitialAd != null) return;
    _isLoadingInterstitial = true;

    InterstitialAd.load(
      adUnitId: MonetizationConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoadingInterstitial = false;
          debugPrint('[AdService] Interstitial ad preloaded successfully');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isLoadingInterstitial = false;
          debugPrint('[AdService] Interstitial preloading error: $error');
        },
      ),
    );
  }

  /// Show Interstitial Ad (with 30-second frequency guard)
  Future<void> showInterstitialAdIfAllowed({BuildContext? context}) async {
    if (IAPService.instance.isVip) return;

    final now = DateTime.now();
    if (_lastInterstitialShown != null &&
        now.difference(_lastInterstitialShown!).inSeconds < 30) {
      return; // Respect 30-second spacing
    }

    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd();
        },
      );
      await _interstitialAd!.show();
      _lastInterstitialShown = DateTime.now();
      return;
    }

    // If preloaded ad is not ready, attempt immediate load and show
    InterstitialAd.load(
      adUnitId: MonetizationConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (a) {
              a.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (a, error) {
              a.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
          );
          ad.show();
          _lastInterstitialShown = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] Immediate interstitial load failed: $error');
        },
      ),
    );
  }

  void loadRewardedAd() {
    if (_isLoadingRewarded || _rewardedAd != null) return;
    _isLoadingRewarded = true;

    RewardedAd.load(
      adUnitId: MonetizationConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoadingRewarded = false;
          debugPrint('[AdService] Rewarded ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoadingRewarded = false;
          debugPrint('[AdService] Rewarded ad failed to load: $error');
        },
      ),
    );
  }

  /// Show Rewarded Ad to unlock a premium DPS control for the current session.
  /// If user is offline, prompts network dialog.
  Future<bool> showRewardedAdForControl({
    BuildContext? context,
    required VoidCallback onUserEarnedReward,
  }) async {
    if (IAPService.instance.isVip) {
      onUserEarnedReward();
      return true;
    }

    final hasNetwork = await isNetworkAvailable();
    if (!hasNetwork) {
      final ctx = AuraMixApp.navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        NetworkRequiredDialog.show(ctx);
      }
      return false;
    }

    if (_rewardedAd == null) {
      debugPrint('[AdService] Rewarded ad not ready, reloading...');
      loadRewardedAd();
      onUserEarnedReward();
      return true;
    }

    bool earned = false;
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
    );

    await _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      earned = true;
      onUserEarnedReward();
    });

    return earned;
  }
}
