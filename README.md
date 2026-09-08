# Stremio Android TV — Dialogue downmix

Patched official Stremio Android TV.
Uninstall the official app first; this APK is signed with a different key.

On **MPV**, each multichannel audio track gets a virtual sibling labeled `<source> (Dialogue downmix)`. Selecting it keeps the original audio track and applies lavfi pan + compressor + limiter. Selecting the original clears the filter.

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

## Versions and ABIs

The DEX overlay does not contain native code. One overlay covers every ABI of a given Stremio version; `lib/` comes from that ABI’s official APK.

Known builds live in `catalog.json` (URL, versionCode, SHA-256). Stremio’s versionCode steps by `0x100000` per ABI (`armeabi-v7a`, `x86`, `arm64-v8a`, `x86_64`).

Overlay layout:

- `overlay/common/` — `MpvDownmixTracks` (shared)
- `overlay/<version>/` — patched `MpvPlayer` for that Stremio release

A new Stremio version needs APKs in `catalog.json` (download one ABI, `sha256sum`, paste hashes). Whether you can reuse `"overlay": "1.10.4"` depends on the player classes, not the version string.

### Did the player classes change?

Decode one ABI of the new APK, then diff the two files we patch against the 1.10.4 overlay:

```sh
apktool d vendor/com.stremio.one-<ver>-<code>-armeabi-v7a.apk -o /tmp/stremio
P=smali_classes6/com/stremio/common/players
diff -u overlay/1.10.4/$P/MpvPlayer.smali /tmp/stremio/$P/MpvPlayer.smali
diff -u overlay/1.10.4/$P/MpvPlayer\$eventObserver\$1.smali /tmp/stremio/$P/MpvPlayer\$eventObserver\$1.smali
```

The overlay files already contain our hooks. **Unchanged** means the only hunks are those hooks (new file is missing them). If so, set `"overlay": "1.10.4"` and stop.

**Changed** means anything else moved: extra methods, different `.locals`, renamed fields (`mpv`, `eventObserver`), different `load`/`setTrack` bodies, or the `track-list` mapper no longer calling `MpvPlayerKt.toTrack`. Do not copy the old player files on top — that would wipe Stremio’s own edits.

Then start from the *new* stock files and re-apply the three hooks:

1. `MpvPlayer.load` — first thing, `MpvDownmixTracks.clear(mpv)` so a new file never starts on downmix.
2. `MpvPlayer.setTrack` — when the track is `AUDIO` and `mpv` is non-null, `MpvDownmixTracks.apply(mpv, track)` and republish `track-list` on `eventObserver` (so the checkmark can move). Leave the original `aid` path for non-audio.
3. `MpvPlayer$eventObserver$1` `track-list` handler — `rememberTrackList(json)` before parse; after `toTrack(json)`, `addAll(MpvDownmixTracks.expand(track, json))` instead of adding the single track.

Save those two patched files under `overlay/<new-version>/` with the same relative smali path. Set `"overlay": "<new-version>"`.

Also glance at `Track.smali` / `MPVLib.smali` if the helper fails to smali. `overlay/common` (`MpvDownmixTracks`) only needs a change if the `Track` constructor/getters or `MPVLib.setProperty*` signatures changed.

```sh
./scripts/build.sh --version <new-version> --abi all
```
