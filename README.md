# Oyun Çevirmeni / Console Game Translator — Android source

<!-- application-links:start -->
**Türkçe / Turkish:** Oyun Çevirmeni  
**English:** Console Game Translator

[Google Play'de görüntüle / View on Google Play](https://play.google.com/store/apps/details?id=com.abrebostudio.consolegametranslator)
<!-- application-links:end -->

This repository contains the Flutter application, Android/Kotlin integration,
modified Chiaki/chiaki-ng core and JNI bindings used by Console Game Translator.
It is a source snapshot prepared on **2026-11-17** from version **1.0.9+10** of the
working tree. It is not a copy of the private development repository's history.

**Publication status:** source preparation, not a completed binary compliance
release. Final binary/source pairing and public source links still need resolution.
ML Kit compatibility is assumed by the publisher for this preparation. See [RELEASE-CHECKLIST.tr.md](RELEASE-CHECKLIST.tr.md).
Do not describe this snapshot as a compliance certificate for an existing APK/AAB.

## Latest source synchronization

Manually refreshed on **2026-11-17** for **1.0.9+10**.
See `release/source-sync.json` for changed, added and removed source paths.
The development checkout and previous snapshots were not modified.

## License and credits

The application-specific source in this snapshot is offered under GNU Affero
General Public License version 3, with the OpenSSL additional permission retained
in [LICENSE](LICENSE). Existing third-party files retain their own notices and
licenses. No new exception for proprietary SDKs is granted by this repository.
Trademark rights are not granted.

The Remote Play implementation is based on [Chiaki / chiaki-ng](https://github.com/chiaki-ng/chiaki-ng).
The imported core identifies itself as version 1.10.0. Original authorship and
copyright notices are preserved in the source files. This is an independent
application and is not an official Chiaki or Sony release.

You may copy, modify and redistribute covered source under its license. The
software is provided without warranty as stated in that license; mandatory
consumer rights are unaffected. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
and [MODIFICATIONS.md](MODIFICATIONS.md).

## Contents

```text
lib/                         Flutter UI, game matching integration, settings, auth and TV clients
android/                     Kotlin/Java, JNI, resources, Gradle wrapper and build configuration
chiaki-native/               Modified Chiaki core and bundled upstream dependencies
assets/                      Assets used by the Android app, font notice, packaged Samsung receiver
samsung_tv/                  Editable sources of the receiver bundled in assets/tv/
third_party/native/          Native dependency source snapshots, including CTranslate2 submodules
third_party/archives/         Hash-verified OpenSSL 1.1.1w source archive
third_party/pub/              Resolved Pub dependency sources
third_party/maven-sources/    Available exact-version Android dependency source JARs
third_party/flutter-framework/ Flutter framework/localization Dart sources for the pinned SDK
LICENSES/                    Upstream licenses and notices for resolved Pub packages
test/                        Application tests and isolated TLS test fixtures
server/game-catalog/         Font/profile fixtures used by tests only; no production backend/data
tool/                        Relevant native verification and receiver packaging scripts
release/                     Source inventory, dependency provenance and publication status
publication/                 Legal/source notice text and an optional standalone legal page
```

See [BUILDING.md](BUILDING.md) for build instructions. Production signing keys,
passwords, Firebase configuration, App Check debug tokens, service-account keys,
server secrets, game translation datasets, private history and build output are
not included. Public service origins and source-code identifiers are not secrets.

The separate iOS skeleton and Android TV receiver application are not part of this
Android source release. They must be handled separately if distributed. The
Samsung receiver actually embedded in the Android app is included in editable form.

## Releases and source availability

For each distributed binary, publish its matching source snapshot as a permanent
tag/release and record the binary SHA-256 in `release/publication.json`. Link that
source release clearly beside the binary/download/store listing; do not rely on
users discovering this repository themselves. Source downloads must be available
without payment or a subscription. A separate public snapshot repository is
compatible with keeping the development repository private.

Nothing in this preparation publishes a repository, changes the working app,
deploys a website or supplies credentials for the publisher's paid services.

Türkçe yayın adımları: [RELEASE-CHECKLIST.tr.md](RELEASE-CHECKLIST.tr.md).
