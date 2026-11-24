import 'dart:io';

/// Centralized Monetization Configuration for AuraMix.
/// Includes Google AdMob IDs (configured with official Google Test IDs by default),
/// RevenueCat / Store In-App Purchase identifiers, and Firebase toggles.
class MonetizationConfig {
  /// MASTER DEVELOPER OVERRIDE FLAG:
  /// Set [isPremium] to `true` to unlock all features across the entire app from code side.
  /// When `true`:
  /// - Full access to all DSP dials & presets (Tube Warmth, Compressor, 3D Spatializer, Cathedral Reverb, etc.)
  /// - All ads (Banner, Interstitial, Rewarded) are disabled
  /// - No network check popups when tweaking sound or playing music (full offline freedom)
  /// - VIP Pro status enabled everywhere in the app
  ///
  /// Set to `false` for standard store monetization with IAP and AdMob ads.
  static const bool isPremium = false;

  // Toggle to switch between local persistent storage mode and Firebase production mode
  static const bool firebaseEnabled = true;

  // Google AdMob App IDs (Replace with your registered AdMob App IDs before production)
  // Android Manifest & iOS Info.plist also use these values
  static const String androidAdMobAppId = 'ca-app-pub-1596973530187567~7133580983';
  static const String iosAdMobAppId = 'ca-app-pub-1596973530187567~7380992996';

  // Google Test Ad Unit IDs (Google guaranteed to serve test ads without policy bans)
  static const String androidBannerTestId = 'ca-app-pub-3940256099942544/6300978111';
  static const String iosBannerTestId = 'ca-app-pub-3940256099942544/2934735716';

  static const String androidInterstitialTestId = 'ca-app-pub-3940256099942544/1033173712';
  static const String iosInterstitialTestId = 'ca-app-pub-3940256099942544/4411468910';

  static const String androidRewardedTestId = 'ca-app-pub-3940256099942544/5224354917';
  static const String iosRewardedTestId = 'ca-app-pub-3940256099942544/1712485313';

  // Production Ad Unit IDs (Replace these with your AdMob account unit IDs)
  static const String prodAndroidBannerId = 'ca-app-pub-1596973530187567/1832940814';
  static const String prodIosBannerId = 'ca-app-pub-1596973530187567/5630208888';

  static const String prodAndroidInterstitialId = 'ca-app-pub-1596973530187567/4834720707';
  static const String prodIosInterstitialId = 'ca-app-pub-1596973530187567/1654023593';

  static const String prodAndroidRewardedId = 'ca-app-pub-1596973530187567/3195617237';
  static const String prodIosRewardedId = 'ca-app-pub-1596973530187567/4088615247';

  // Set to false to use production Ad IDs
  static const bool useTestAds = false;

  static String get bannerAdUnitId {
    if (useTestAds) {
      return Platform.isAndroid ? androidBannerTestId : iosBannerTestId;
    }
    return Platform.isAndroid ? prodAndroidBannerId : prodIosBannerId;
  }

  static String get interstitialAdUnitId {
    if (useTestAds) {
      return Platform.isAndroid ? androidInterstitialTestId : iosInterstitialTestId;
    }
    return Platform.isAndroid ? prodAndroidInterstitialId : prodIosInterstitialId;
  }

  static String get rewardedAdUnitId {
    if (useTestAds) {
      return Platform.isAndroid ? androidRewardedTestId : iosRewardedTestId;
    }
    return Platform.isAndroid ? prodAndroidRewardedId : prodIosRewardedId;
  }

  // In-App Purchase / RevenueCat Product IDs
  static const String iapMonthlyId = 'auramix_vip_monthly';
  static const String iapYearlyId = 'auramix_vip_yearly';
  static const String iapLifetimeId = 'auramix_vip_lifetime';

  static const String revenueCatAndroidPublicSdkKey = 'goog_REPLACE_WITH_YOUR_KEY';
  static const String revenueCatIosPublicSdkKey = 'appl_REPLACE_WITH_YOUR_KEY';

  // Premium Feature Control Keys (used for rewarded ad unlocks)
  static const String controlTubeWarmth = 'dps_tube_warmth';
  static const String controlCompressor = 'dps_compressor';
  static const String controlSurround3D = 'dps_surround_3d';
  static const String controlReverbCathedral = 'dps_reverb_cathedral';
  static const String controlPitchShift = 'dps_pitch_shift';
  static const String controlCustomUnlimited = 'dps_custom_unlimited';
}
