# AuraMix Flutter Source Bundle

This archive contains the Flutter/Dart app source currently available for AuraMix, including `lib/`, `pubspec.yaml`, audio/image assets, docs, and a platform bootstrap script.


## Included
- Flutter/Dart app source (`lib/main.dart`, core sound engine, monetization config)
- Ten generated ambient WAV assets and app icon
- Dependency manifest and launcher-icon configuration
- Setup, feature, and release documentation
- `bootstrap_platforms.sh` to generate Android and iOS folders using an installed Flutter SDK, then overlay AuraMix sources and permissions

## Important limitation
Android/iOS native folders are not pre-generated in this bundle. The Flutter SDK was not available in the packaging environment, so the project could not be compiled, analyzed, or device-tested. This is source code, not a build-verified release project. Firebase, rewarded ads, and RevenueCat are still demo/configuration integrations and require real credentials and implementation before production.

## Generate platform folders
From the extracted project folder, run:
```bash
chmod +x bootstrap_platforms.sh
./bootstrap_platforms.sh
flutter run
```
