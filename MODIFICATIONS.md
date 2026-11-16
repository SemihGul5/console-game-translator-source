# Modifications and provenance

Snapshot date: 2026-11-07. Application version in `pubspec.yaml`: 1.0.3+4.

The imported Chiaki core identifies itself as 1.10.0. This is a modified source
tree, not a claim that every file is pristine upstream v1.10.0. The upstream
license copy matches `chiaki-ng/v1.10.0/COPYING`, SHA-256
`fff3acb5eddbde97746cc1ad2082a1e95f50c2315a8748b26b8a81a499d8d216`.
Original file headers and third-party notices remain in place.

Application integration/modifications present in the snapshot include:

- Android CMake integration and JNI bindings for Remote Play, audio and video.
- Windows OpenSSL path detection/install patches and Android 16 KB page-size linking.
- Kotlin console discovery, registration, session control, credentials storage and lifecycle.
- Frame capture, on-device OCR/translation and subtitle rendering/TV delivery.
- Flutter screens, preferences, account/access integration and game dictionary loading.
- Safe sentence alignment, OCR matching indexes and bounded prepared-game caching.
- SentencePiece/CTranslate2 JNI integration and pinned downloadable model metadata.
- An Android-specific CTranslate2 thread-pool guard excluding `pthread_setaffinity_np`.

These are changes by the application project, not endorsements by upstream authors.

## Changes made only in this public copy

1. Add source-publication documentation, license copies, notices and integrity tools.
2. Supply OpenSSL's original, hash-verified source archive and source snapshots of
   SentencePiece, CTranslate2 (with the enabled Ruy/spdlog submodules), json-c and MiniUPnPc.
   The existing Android thread-pool guard is reapplied by CMake when configuring;
   the bundled CTranslate2 file is retained in its copied pre-configuration form.
3. Select those bundled native snapshots in the copied CMake configuration. The
   OpenSSL archive hash and the existing patch/build steps are retained.
4. Remove the production broker default from copied `android/gradle.properties`;
   use the documented build property/environment variable instead.
5. Add ignore rules and configuration examples. Production configuration and
   credentials are excluded, rather than replaced in the private working app.

Application Dart/Kotlin/Java/C/C++ sources and packaged app assets are copied
without edits. `release/snapshot-files.json` records the original copied file
hashes. `release/public-copy-changes.json` records the three build-only file
changes and their hashes. `release/SHA256SUMS` inventories the prepared public
files, excluding its own generated inventory and validation reports.

No private Git history is included. No private development file is modified by
this preparation. A source tag for a real store release must be updated to match
that release's exact code; this working-tree snapshot does not retroactively
describe previously built APKs/AABs.

Turkish branding refreshed to AnlaOyna; store/site title: AnlaOyna: Konsol Oyun Çevirisi. Package identifiers and application behavior are unchanged.


Manual source refresh: 2026-11-16, version 1.0.7+8.
See release/source-sync.json for the changes relative to the reviewed seed.
