# AuraMix setup and release checklist

## 0. Project identity
- App display name: `AuraMix`.
- Starter Android application ID / iOS bundle ID: `com.example.auramix` (change to your permanent reverse-domain ID before Firebase/store setup).
- App icon source: `assets/images/auramix_icon.png`.
- Flutter target: **3.47.9**. The project has not been compiled in this environment (Flutter SDK unavailable).

## 1. Generate native folders and icon files
Run from project root using Flutter 3.47.9:
```bash
chmod +x bootstrap_platforms.sh
./bootstrap_platforms.sh
```
The script generates `android/` and `ios/`, overlays app source/assets/docs, adds Android fine/coarse location permission, sets native display names to AuraMix, adds iOS location purpose strings, and runs `flutter pub get` and launcher icon generation.

## 2. Firebase
1. Create Firebase project.
2. Add Android app using your chosen application ID. Place downloaded `google-services.json` at `android/app/google-services.json`.
3. Add iOS app using bundle ID. Place `GoogleService-Info.plist` at `ios/Runner/GoogleService-Info.plist`.
4. Install FlutterFire CLI and run `flutterfire configure`; retain/update `lib/firebase_options.dart` if the CLI generates it.
5. Enable Firebase Authentication -> Email/Password.
6. Enable Firestore, Storage, Functions, Analytics, Crashlytics and Remote Config as needed.
7. Set `firebaseEnabled = true` in `lib/core/monetization_config.dart` only after Firebase files/native config are installed.
8. Review and deploy secure Firestore/Storage rules and Cloud Functions; never allow clients to edit reaction/play counters or premium entitlements.

## 3. AdMob
Update IDs in `lib/core/monetization_config.dart` (or centralize these before production):
- Android AdMob app ID
- iOS AdMob app ID
- Android banner ad unit ID
- iOS banner ad unit ID
- Android rewarded ad unit ID
- iOS rewarded ad unit ID

Native app IDs are also required in `android/app/src/main/AndroidManifest.xml` as Google Mobile Ads `APPLICATION_ID` metadata and in `ios/Runner/Info.plist` as `GADApplicationIdentifier`. Add UMP consent flow, test devices, ad callbacks, and policy-safe placements. Reward access must be granted only from the rewarded-earned callback, not merely when an ad closes. Do not use test ads in production.

## 4. RevenueCat / IAP
Update public SDK keys in `lib/core/monetization_config.dart`:
- Android public SDK key
- iOS public SDK key
Configure products/offerings/entitlements in RevenueCat and store consoles. Suggested entitlement: `premium`; suggested products: `auramix_monthly`, `auramix_yearly`, `auramix_lifetime` (IDs must match exactly across store and RevenueCat). Test purchases, pending/cancelled/failure states, expiry, renewal, billing grace period, cross-device entitlement, and restore. Premium must be based on verified entitlement, never a local boolean.

## 5. Audio assets
Audio assets are in `assets/audio/` and referenced in `lib/core/sound_engine.dart`. Current bundled WAVs are generated prototype ambience textures (not field-recorded nature sounds): `rain.wav`, `ocean.wav`, `forest.wav`, `fireplace.wav`, `wind.wav`, `birds.wav`, `white_noise.wav`, `brown_noise.wav`, `pink_noise.wav`, `cafe.wav`. Replace with licensed sound recordings before release and document asset/license provenance.

## 6. Local music and GPS
- Local music picker uses system file picker, so it does not require broad shared-storage permission. The selected audio is played from the local file and not uploaded.
- Android GPS permission: `ACCESS_COARSE_LOCATION` and `ACCESS_FINE_LOCATION` (bootstrap adds these).
- iOS location purpose text is in `ios/Runner/Info.plist` (`NSLocationWhenInUseUsageDescription`).
- GPS screen currently only requests a location fix and displays coordinates. Actual geofence automation/automatic playback triggers are not implemented.
- Imported music currently plays in the foreground; background audio service/lock-screen controls are not implemented yet.

## 7. Authentication / profile
- The startup gate requires a profile before the main app.
- With Firebase disabled, profile/email are saved locally as a **demo profile only**, not secure user authentication.
- With Firebase enabled, email/password sign-up and sign-in use Firebase Auth. Enable the provider in Firebase Console and set `firebaseEnabled = true`.
- Add password reset, email verification, account deletion, social sign-in and server-side profile synchronization before release.

## 8. Permissions included/requested
- Location coarse/fine: requested only when user taps the GPS/location control.
- Audio file import: system picker, avoids broad file/media permissions.
- Internet: generated Flutter Android manifest normally includes `INTERNET`; verify before release.
- No background location permission is requested. Do not add it unless a clear background geofencing feature is implemented and justified.

## 9. Store readiness
- Change package/bundle identifiers and signing.
- Add app icon/launch branding and store screenshots.
- Privacy policy, terms, support contact, data deletion.
- Audio licenses and user-upload content moderation.
- Store subscription disclosures, price, renewal terms and restore.
- Ad consent/privacy disclosures and data safety forms.
- Crash reporting, analytics events, rate limits, abuse controls.
- Test on physical Android and iOS devices, including audio focus, interruptions, headphones/Bluetooth, offline mode, GPS denied/denied permanently, picker cancellation, purchases and restore.
