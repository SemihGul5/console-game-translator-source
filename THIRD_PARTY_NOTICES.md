# Third-party notices

## Chiaki / chiaki-ng

Remote Play code and Android JNI bindings are derived from
<https://github.com/chiaki-ng/chiaki-ng>. Copyright remains with the authors and
contributors named in the preserved source-file notices. Imported SPDX identifier:
`LicenseRef-AGPL-3.0-only-OpenSSL`. The full license and OpenSSL additional
permission are in [LICENSE](LICENSE) and `chiaki-native/COPYING`.

The application-specific covered source is offered under those terms. Original
third-party components retain their licenses. The upstream projects are not the
provider of this application's paid services or support. There is no warranty
except as required by applicable law or separately agreed.

## Native libraries

| Component | License/notice | Source location |
| --- | --- | --- |
| OpenSSL 1.1.1w | OpenSSL and SSLeay; `LICENSES/existing-notices/OpenSSL.txt` | `third_party/archives/openssl-1.1.1w.tar.gz`; patch/build scripts in `chiaki-native/cmake/` |
| curl | curl license; `chiaki-native/third-party/curl/COPYING` | `chiaki-native/third-party/curl/` |
| nanopb | zlib; `chiaki-native/third-party/nanopb/LICENSE.txt` | `chiaki-native/third-party/nanopb/` |
| Jerasure / GF-Complete | BSD notices in each `COPYING` | `chiaki-native/third-party/` |
| json-c / MiniUPnPc | MIT / BSD notices in their source | `third_party/native/json-c/`, `third_party/native/miniupnpc/` |
| SentencePiece 0.2.0 | Apache-2.0; source `LICENSE` | `third_party/native/sentencepiece/` |
| CTranslate2 | MIT; source `LICENSE` | `third_party/native/ctranslate2/` |
| Ruy / spdlog | Their preserved upstream licenses | CTranslate2 `third_party/ruy/` and `third_party/spdlog/` |
| Oboe 1.10.0 | Apache-2.0 | <https://github.com/google/oboe/tree/1.10.0> |
| LiteRT 1.4.2 | Apache-2.0 and bundled notices | <https://github.com/google-ai-edge/LiteRT> |
| Android NDK libc++ | LLVM notice | `LICENSES/existing-notices/LLVM-libcxx.txt` |

The native revision inventory is in `release/native-dependencies.json`. SDK and
Maven dependencies remain declared in Gradle; their distribution terms must also
be honored. Presence in this table does not override any component's license.

## Flutter and packages

Flutter is BSD-3-Clause licensed; see `LICENSES/Flutter-LICENSE.txt`. Exact Pub
versions are in `pubspec.lock`. License/notice copies for resolved packages are in
`LICENSES/pub/`, indexed in `release/pub-dependencies.json`. RevenueCat notices
are also retained in `LICENSES/existing-notices/`.

Resolved Pub package sources are bundled in `third_party/pub/`; available exact
Maven source JARs are in `third_party/maven-sources/`. The resolved Maven license
inventory is `release/maven-dependencies.json`; extracted artifact notices are in
`LICENSES/maven/`. Some Google Play/Billing/identity/Firebase dependencies also
declare restricted Google/Android SDK terms. They require review alongside ML
Kit; see `release/SDK-REVIEW.tr.md`. Unknown/missing POM metadata is not a license grant.

## Google ML Kit — unresolved combined-distribution permission

The build includes `com.google.mlkit:text-recognition:16.0.1` and
`com.google.mlkit:translate:17.0.3`. Their APIs/related software are subject to
[ML Kit terms](https://developers.google.com/ml-kit/terms) and
[Google API terms](https://developers.google.com/terms), not an AGPL permission
created by this repository. Public sample-code licenses do not establish the
license of the binary SDKs or models. The Chiaki license grants an OpenSSL
additional permission; no ML Kit-specific permission has been verified.

This is an outstanding compatibility/redistribution question for the combined
binary. Source publication alone is not a resolution. Before binary distribution,
establish an applicable permission/license basis with the relevant rightsholders,
or use a compatible implementation in a separately reviewed release. Nothing in
this package changes the working application's OCR or translation implementation.

## Models, font and data

The downloadable HPLT English-to-Turkish model is derived from
[HPLT/translate-en-tr-v2.0-hplt_opus](https://huggingface.co/HPLT/translate-en-tr-v2.0-hplt_opus)
and [WindyTranslate/translate-windy-hplt-en-tr](https://huggingface.co/WindyTranslate/translate-windy-hplt-en-tr).
It is quantized to INT8 and repackaged for CTranslate2. Attribution is to HPLT for
the original model and WindyTranslate for conversion; license CC-BY-4.0, copied in
`LICENSES/existing-notices/CC-BY-4.0.txt`. Pinned revision/hashes are recorded in
`HpltModelCatalog.kt`. Other downloadable model metadata is in the corresponding
Android catalog code and `LICENSES/existing-notices/opus-models.json`.

Inter font is by the Inter Project authors and licensed under SIL Open Font
License 1.1; see `LICENSES/Inter-OFL.txt`. Test font/profile fixtures contain no
game translations. Separately downloaded dictionaries, game artwork and other
third-party content require their own applicable permissions/attribution.
