# AuraMix - Capriccio-Inspired DPS Sound Effect & Car Cockpit Music Player

AuraMix is a full-featured cross-platform (Android & iOS) music player and DPS (Digital Power Station) acoustic processor built in Flutter for **Android Studio Quail 1 | 2026.1.1 Patch 2** and **Flutter 3.47.x**.

---

## 🌟 Key Architecture & Features

### 1. DPS Sound Effect Studio (Inspired by Capriccio)
- **10-Band Graphic Equalizer** with sliders from `-12 dB` to `+12 dB` (Frequencies: `31Hz, 63Hz, 125Hz, 250Hz, 500Hz, 1kHz, 2kHz, 4kHz, 8kHz, 16kHz`).
- **Acoustic Enhancement Dials (Glowing Rotary Knobs)**:
  - **Sub-Bass Boost**: Deep, punchy low-frequency extension.
  - **3D Spatial Virtualizer**: Broadens the stereo image for cabin/concert acoustics.
  - **Vocal Clarity**: Enhances vocal presence and treble crispness.
  - **Analog Tube Warmth**: Emulates vintage vacuum tube harmonic saturation.
  - **Dynamic Studio Compressor**: Levels loud and quiet passages for road-noise-resistant playback.
- **Acoustic Spaces**: Studio, Club, Arena, Cathedral reverb simulation.
- **Pitch & Speed Control**: Real-time tempo adjustment from `0.5x` to `2.0x`.

### 2. Local Audio & Song Player
- Scans and loads local device tracks (`.mp3`, `.wav`, `.m4a`, `.flac`, `.aac`, `.ogg`) via file picker with permission handling (`READ_MEDIA_AUDIO` on Android 13+, `READ_EXTERNAL_STORAGE` on older Android versions, `NSAppleMusicUsageDescription` on iOS).
- Full playback transport: Play/Pause, Seek bar, Skip Next/Prev, Shuffle, and Repeat/Loop modes.
- Playback queue management with on-the-fly track reselection.

### 3. Community Sound Lab (Preset Sharing & Discovery)
- **Custom DPS Presets**: Save custom equalizer, bass, and tube parameters.
- **Privacy Controls**:
  - `Private (Only Me)`: Only visible on creator's device.
  - `Public (Share to Community)`: Published to global community feed.
- **Like & Dislike Voting**: Upvote or downvote presets with real-time counters.
- **Sorting & Filtering**:
  - Sort by: Most Liked, Most Plays, Newest First, Alphabetical.
  - Filter by Category: All, Car Audio, Bass Heavy, Acoustic, Vocal, General.
  - Visibility: All, Public Community Feed, My Private Presets, Liked Presets.
- **Song Recommendations ("Best Songs for this Control")**:
  - Community members can recommend songs that sound phenomenal with a specific preset.
  - Browse recommended songs and submit your own track suggestions with comments.

### 4. Rewarded Ads & VIP Monetization
- **Rewarded Ad Session Unlock**:
  - If a control or preset is marked as **Premium**, free users tap it and choose:
    1. **"Watch Video Ad (1 Session Pass)"**: Shows Google AdMob Rewarded Ad; grants session access to that control.
    2. **"Get AuraMix VIP Pro"**: Unlocks all controls permanently and removes all ads.
- **In-App Purchase (IAP)**: Monthly, Yearly, and Lifetime VIP tiers.
- **Restore Purchases**: Integrated restore button for App Store / Google Play entitlements.
- **Google AdMob Integration**: Banner ads, interstitial cooldowns, and rewarded video ad loaders.

### 5. Car Cockpit HUD Mode & Animated Neon UI
- High-contrast, night-drive obsidian dark aesthetic (`#07080F`, `#131733`) with glowing neon gradients (Cyan, Magenta/Purple, Amber, Neon Green).
- **Animated Audio Visualizer**: 24 binned spectrum bars responding to audio playback and tempo.
- **Dual Analog VU Meters**: Real-time left and right channel needle deflection gauges.
- **Rotating Vinyl Turntable**: Smooth RPM rotation while music is actively playing.
- **Car HUD Mode**: Dedicated driving-safe full-screen HUD with giant 88px touch buttons, speedometer/clock display, and instant cabin tuning presets (Highway Roar, Night Cabin, City Cruiser, Subwoofer Max).

---

## 📁 Exact File Paths to Update Before Production

| Component | File Path | What to Update |
| :--- | :--- | :--- |
| **AdMob Ad Units & Toggle** | `lib/core/monetization_config.dart` | Set `useTestAds = false` and insert your production AdMob Banner, Interstitial, and Rewarded Ad IDs. |
| **Android AdMob App ID** | `android/app/src/main/AndroidManifest.xml` | Replace `ca-app-pub-3940256099942544~3347511713` under `<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID">`. |
| **iOS AdMob App ID** | `ios/Runner/Info.plist` | Replace `ca-app-pub-3940256099942544~1458002511` under `<key>GADApplicationIdentifier</key>`. |
| **Firebase Android (JSON)** | `android/app/google-services.json` | Drop your downloaded `google-services.json` directly into `android/app/`. |
| **Firebase iOS (Plist)** | `ios/Runner/GoogleService-Info.plist` | Drop your downloaded `GoogleService-Info.plist` into `ios/Runner/`. |
| **Enable Firebase Mode** | `lib/core/monetization_config.dart` | Change `firebaseEnabled = false` to `firebaseEnabled = true` once Firebase JSON/Plist files are in place. |
| **In-App Purchase Keys** | `lib/core/monetization_config.dart` | Set `revenueCatAndroidPublicSdkKey` and `revenueCatIosPublicSdkKey` from your RevenueCat dashboard. |
| **Android Application ID** | `android/app/build.gradle` | Change `namespace` and `applicationId` (currently `com.example.auramix`) to your registered package name. |
| **iOS Bundle Identifier** | `ios/Runner/Info.plist` | Change `CFBundleIdentifier` to your Apple Developer registered App ID. |

---

## 🚀 Running in Android Studio Quail & Flutter 3.47.x

1. Open this folder (`auramix_flutter`) in **Android Studio Quail 1 | 2026.1.1 Patch 2**.
2. Run `flutter pub get` in terminal or click **Pub get** in Android Studio.
3. To generate platform launcher icons:
   ```bash
   flutter pub run flutter_launcher_icons
   ```
4. Connect an Android device/emulator or iOS simulator and click **Run** (`flutter run`).
