#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
TMP="${ROOT}/.platform_bootstrap_tmp"
if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK not found. Install Flutter and run this script again." >&2
  exit 1
fi
rm -rf "$TMP"
flutter create --platforms=android,ios --org com.example --project-name auramix "$TMP"
cp "$ROOT/pubspec.yaml" "$TMP/pubspec.yaml"
rm -rf "$TMP/lib" "$TMP/assets"
cp -R "$ROOT/lib" "$TMP/lib"
cp -R "$ROOT/assets" "$TMP/assets"
cp -R "$ROOT/docs" "$TMP/docs"
cp "$ROOT/README.md" "$TMP/README.md"
# App identity, optional GPS permission, media pickers, and icon setup.
# Android: location is requested only when the user taps the GPS control.
MANIFEST="$TMP/android/app/src/main/AndroidManifest.xml"
python3 - "$MANIFEST" <<'PYMAN'
import sys
from pathlib import Path
p=Path(sys.argv[1]); s=p.read_text()
perms='\n    <uses-permission android:name=\"android.permission.ACCESS_COARSE_LOCATION\" />\n    <uses-permission android:name=\"android.permission.ACCESS_FINE_LOCATION\" />'
if 'ACCESS_COARSE_LOCATION' not in s: s=s.replace('<application', perms+'\n    <application', 1)
s=s.replace('android:label=\"auramix\"','android:label=\"AuraMix\"')
p.write_text(s)
PYMAN
PLIST="$TMP/ios/Runner/Info.plist"
python3 - "$PLIST" <<'PYPLIST'
import sys, plistlib
from pathlib import Path
p=Path(sys.argv[1]); d=plistlib.loads(p.read_bytes())
d['CFBundleDisplayName']='AuraMix'
d['NSLocationWhenInUseUsageDescription']='AuraMix uses your location only when you enable location-aware sound controls.'
d['NSLocationAlwaysAndWhenInUseUsageDescription']='AuraMix can use location for optional location-aware sound profiles when enabled.'
d['UIBackgroundModes']=[mode for mode in d.get('UIBackgroundModes',[]) if mode != 'audio']
p.write_bytes(plistlib.dumps(d))
PYPLIST
# Replace the project folder with the generated, platform-complete Flutter project.
for d in android ios; do rm -rf "$ROOT/$d"; cp -R "$TMP/$d" "$ROOT/$d"; done
cp "$TMP/.gitignore" "$ROOT/.gitignore" 2>/dev/null || true
rm -rf "$TMP"
cd "$ROOT"
flutter pub get
flutter pub run flutter_launcher_icons
printf '\nBootstrap complete. Open this folder in your IDE and run flutter run.\n'
