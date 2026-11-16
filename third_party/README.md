# Dependency source snapshots

- `native/`: the SentencePiece, CTranslate2/Ruy/spdlog, json-c and MiniUPnPc source
  trees actually present in the native build cache. Git metadata and compiled
  objects are omitted. The CTranslate2 Android thread-pool patch is reapplied by
  the existing application CMake script when configuring a build.
- `archives/openssl-1.1.1w.tar.gz`: the original OpenSSL archive with the SHA-256
  pinned by the application's build. The accompanying CMake scripts apply the
  original application's patches. This source is supplied for the OpenSSL
  additional permission, not just linked to an upstream website.
- `pub/`: resolved package source snapshots matching `pubspec.lock`. Original
  package licenses remain in each package. Upstream example/test Firebase config
  files are omitted as recorded in `release/omitted-upstream-example-configs.json`;
  library implementation sources are retained. These sources are provided for
  inspection/modification; Pub still resolves dependencies normally when building.
- `maven-sources/`: 93 available exact-version dependency source JARs. They are
  source archives, not binary runtime replacements. `release/maven-dependencies.json`
  records 165 resolved Maven coordinates, discovered POM licenses and source-JAR
  availability. Missing POM metadata or sources is not an AGPL compatibility finding.
- `flutter-framework/`: Dart sources for Flutter and Flutter localizations from
  the pinned Flutter 3.41.1 SDK. Build with that normal SDK as described in BUILDING.md.

The development toolchains, Android SDK/NDK and Flutter/Dart engine are obtained
through their normal official distributions. SDK/engine revision information is
recorded in BUILDING.md. A bundled source snapshot does not itself grant new
rights to any restricted third-party SDK or to a publisher's services/accounts.

Licenses are preserved with the source and under `LICENSES/`. Public upstream
test data can contain test certificates/keys; these are not publisher credentials.
