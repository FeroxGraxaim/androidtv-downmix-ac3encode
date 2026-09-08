# Stremio Android TV — Dialogue downmix

Sideload of official Stremio Android TV **1.10.4**. Same package: `com.stremio.one`.
Uninstall the official app first; this APK is signed with a different key.

On **MPV**, each multichannel audio track gets a virtual sibling (`downmix:<aid>`), labeled `<source> (Dialogue downmix)`. Selecting it keeps the real `aid` and applies lavfi pan + compressor + limiter. Selecting the original clears the filter. Downmix is never the default.

## Need

- Official APK (the build script downloads it, or put it in `vendor/`)
- `apktool`, `zipalign`, `apksigner`, `keytool`

Upstream: https://dl.strem.io/android/v1.10.4-androidTV/com.stremio.one-1.10.4-31048580-armeabi-v7a.apk  
SHA-256 `e18a5405bb53e12a903ff477457318b8f8d3c8e1995e0a4c3ff5d8893d1ccf0b`

## Build

```sh
./scripts/build.sh
```

Output: `dist/stremio-androidtv-downmix-1.10.4.apk`

A keystore is created at `signing/downmix.jks` on the first run. Keep it if you want later patched builds to upgrade in place.

```sh
adb uninstall com.stremio.one
adb install dist/stremio-androidtv-downmix-1.10.4.apk
```

`vendor/`, `work/`, `dist/`, and `signing/` are local only.
