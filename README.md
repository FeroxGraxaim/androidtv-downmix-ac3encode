# Stremio Android TV — Dialogue downmix

Patched official Stremio Android TV. Same package: `com.stremio.one`.
Uninstall the official app first; this APK is signed with a different key.

On **MPV**, each multichannel audio track gets a virtual sibling (`downmix:<aid>`), labeled `<source> (Dialogue downmix)`. Selecting it keeps the real `aid` and applies lavfi pan + compressor + limiter. Selecting the original clears the filter. Downmix is never the default.

## Need

`apktool`, `zipalign`, `apksigner`, `keytool`. Official APKs are downloaded into `vendor/` (or drop them there yourself).

## Build

```sh
./scripts/build.sh --list
./scripts/build.sh                          # 1.10.4 armeabi-v7a
./scripts/build.sh --abi arm64              # 1.10.4 arm64-v8a
./scripts/build.sh --abi all                # every ABI for the default version
./scripts/build.sh --version 1.10.4 --abi x86_64
```

Output: `dist/stremio-androidtv-downmix-<version>-<abi>.apk`

```sh
adb uninstall com.stremio.one
adb install dist/stremio-androidtv-downmix-1.10.4-armeabi-v7a.apk
```

A keystore is created at `signing/downmix.jks` on the first run. Keep it so later patched builds upgrade in place.

`vendor/`, `work/`, `dist/`, and `signing/` are local only.

## Versions and ABIs

The DEX overlay does not contain native code. One overlay covers every ABI of a given Stremio version; `lib/` comes from that ABI’s official APK.

Known builds live in `catalog.json` (URL, versionCode, SHA-256). Stremio’s versionCode steps by `0x100000` per ABI (`armeabi-v7a`, `x86`, `arm64-v8a`, `x86_64`).

Overlay layout:

- `overlay/common/` — `MpvDownmixTracks` (shared)
- `overlay/<version>/` — patched `MpvPlayer` for that Stremio release

A new Stremio version needs a new overlay. `MpvPlayer.smali` changes; copying an old player file will drop upstream fixes.

1. Add the APKs to `catalog.json` (download once, `sha256sum`, paste hashes). You can reuse `"overlay": "1.10.4"` only if you have checked the player classes are unchanged.
2. Decode one ABI: `apktool d vendor/<apk> -o /tmp/stremio`.
3. Copy `overlay/common` in, then re-apply the three hooks in `overlay/1.10.4`’s `MpvPlayer.smali` / `MpvPlayer$eventObserver$1.smali` (`clear` on `load`, `apply` on `setTrack`, `rememberTrackList` + `expand` on `track-list`).
4. Save the patched player files under `overlay/<new-version>/`.
5. `./scripts/build.sh --version <new-version> --abi all`
