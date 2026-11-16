# Building the Android source snapshot

## Toolchain

The development checkout used Flutter **3.41.1** (framework revision
`582a0e7c5581dc0ca5f7bfd8662bb8db6f59d536`, Dart **3.11.0**), JDK **17**,
Gradle **8.14**, Android Gradle Plugin **8.11.1**, Kotlin **2.4.21**, Android
NDK **28.2.13676358** and CMake **3.22.1**. Install Android SDK platform 36 and
the build tools selected by Gradle/Flutter. The manifest requires Android API 24+.

The native build also needs Python 3, the Python `protobuf` module, `protoc`,
Perl and GNU Make in PATH. On Windows the existing OpenSSL scripts support
Strawberry Perl and GNU Make and select `no-asm`; keep those scripts intact.

The lockfile pins the Dart packages. Gradle resolves Maven artifacts from Google
and Maven Central; SDK/package downloads require internet access. Native sources
listed in `release/native-dependencies.json` are bundled in this snapshot.
See [MODIFICATIONS.md](MODIFICATIONS.md) for the public-copy-only mirror changes.

## Debug build

From a clone of this repository, with Flutter and Android SDK configured:

```sh
flutter pub get
flutter build apk --debug
```

On Unix, if necessary, first run `chmod +x android/gradlew`.
Flutter generates `android/local.properties` for the local SDK paths. The debug
APK is written to `build/app/outputs/flutter-apk/app-debug.apk`. Gradle can compile
without a `google-services.json`; this does not configure the account or catalog
services at runtime.

To use accounts, Google sign-in, App Check, purchases and authenticated services,
configure **your own** Firebase/Google and RevenueCat projects. Register the Android
application ID used by your build and your signing certificate. Download your own
Firebase `google-services.json` to `android/app/`; enable the required providers,
Firestore rules, App Check configuration and your own entitlement/catalog services.
The publisher's service access is not supplied by the source license.

Copy `android/access.properties.example` to `android/access.properties` and fill in
your public RevenueCat SDK key and your own published policy URLs. Server API
secrets and signing passwords must never be compiled into application source.
For debug App Check use a token from your own Firebase project in a local,
ignored `android/appcheck-debug.properties`, if needed.

The broker origin is passed as `PSN_BROKER_URL` in the environment (or as Gradle
property `psnBrokerUrl`). The catalog origin is selectable at compile time:

```sh
flutter build apk --debug --dart-define=GAME_CATALOG_URL=https://YOUR_CATALOG_HOST/catalog.json
```

The client code contains the service interfaces and request/response handling.
Separate deployed backend services and their data are not copied here. For a fork,
operate compatible services or modify the client. Do not send test traffic,
credentials or attestation debug tokens to the publisher's production services.

## Release build with your own signing key

Configure `android/key.properties` locally with `storeFile`, `storePassword`,
`keyAlias` and `keyPassword` pointing to **your own** keystore. Keep both files out
of Git. The existing release checks require Firebase configuration, a valid
RevenueCat public SDK key, HTTPS policy URLs and a valid broker origin.

```sh
flutter build appbundle --release --build-name=YOUR_VERSION --build-number=YOUR_BUILD_NUMBER
```

The build number/name must match the binary/source release being published.
Rebuilding with different Firebase settings or a different signing key does not
reproduce the publisher's signature. No signing key is required to read, modify or
build the source; use your own key to install a modified build. A differently
signed APK cannot update an existing signed installation in place.

## Validation

```sh
node tool/verify_source_release.mjs
flutter test
cd android
./gradlew testDebugUnitTest --tests '*GameTranslationMemory*' --tests '*SubtitleSourceSelectorTest'
```

The TLS private keys under `test/fixtures/tv_tls/` and upstream dependency test
keys are isolated, non-production test data. They are not signing credentials or
secrets for any service. Never use test keys in a deployed service.

The OPUS-MT and HPLT model weights and game dictionaries are not embedded in this
source release. Download code, pinned model revisions/hashes and attribution
information are included; the model/data licenses apply separately.
