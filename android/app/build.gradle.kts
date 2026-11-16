import java.net.URI
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("kotlin-parcelize")
    id("dev.flutter.flutter-gradle-plugin")
}

// Public SDK key and policy URLs only. No custom access server is required.
val accessProperties = Properties().apply {
    val file = rootProject.file("access.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
fun accessValue(name: String): String = providers.environmentVariable(name)
    .orElse(accessProperties.getProperty(name, "")).get().trim()
fun quoted(value: String): String = "\"" + value.replace("\\", "\\\\").replace("\"", "\\\"") + "\""
val revenueCatPublicKey = accessValue("REVENUECAT_PUBLIC_KEY")
val privacyUrl = accessValue("PRIVACY_POLICY_URL")
val termsUrl = accessValue("TERMS_OF_USE_URL")
val googleServicesFile = file("google-services.json")
if (googleServicesFile.exists()) apply(plugin = "com.google.gms.google-services")
val releaseKeys = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
// Local attestation is a debug-only convenience. Release always uses Play Integrity.
val appCheckDebugProperties = Properties().apply {
    val file = rootProject.file("appcheck-debug.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val validateAccessRelease = tasks.register("validateAccessRelease") {
    doLast {
        check(googleServicesFile.exists()) { "Firebase google-services.json is required for account trials. See server/access/SETUP.tr.md." }
        check(revenueCatPublicKey.startsWith("goog_") && !revenueCatPublicKey.contains("REPLACE", ignoreCase = true)) {
            "Configure android/access.properties. See server/access/SETUP.tr.md."
        }
        check(listOf("storeFile", "storePassword", "keyAlias", "keyPassword").all { !releaseKeys.getProperty(it).isNullOrBlank() }) {
            "Release signing requires android/key.properties; debug-signed releases are blocked."
        }
        check(listOf(privacyUrl, termsUrl).all { value ->
            runCatching { URI(value).let { it.scheme == "https" && !it.host.isNullOrBlank() && it.rawUserInfo == null } }.getOrDefault(false)
        }) { "Set published PRIVACY_POLICY_URL and TERMS_OF_USE_URL in android/access.properties." }
    }
}
tasks.configureEach { if (name == "preReleaseBuild") dependsOn(validateAccessRelease) }

// Public HTTPS origin only. Never pass Sony or Turnstile secrets to Gradle.
val psnBrokerOrigin = providers.gradleProperty("psnBrokerUrl")
    .orElse(providers.environmentVariable("PSN_BROKER_URL"))
    .getOrElse("").trim().removeSuffix("/")
val psnBrokerOriginValid = runCatching {
    val uri = URI(psnBrokerOrigin)
    uri.scheme == "https" && !uri.host.isNullOrEmpty() && uri.rawUserInfo == null &&
        uri.port in listOf(-1, 443) && uri.rawPath.isNullOrEmpty() &&
        uri.rawQuery == null && uri.rawFragment == null &&
        !uri.host.lowercase().contains("replace-me")
}.getOrDefault(false)

val validatePsnBrokerRelease = tasks.register("validatePsnBrokerRelease") {
    doLast {
        check(psnBrokerOriginValid) {
            "Release requires a deployed PSN broker: set PSN_BROKER_URL to its HTTPS origin. See server/psn-broker/README.md."
        }
    }
}
tasks.configureEach {
    if (name == "preReleaseBuild") dependsOn(validatePsnBrokerRelease)
}

android {
    namespace = "com.abrebostudio.consolegametranslator"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    // Unit tests read the exact correction table bundled in the APK.
    sourceSets.getByName("test").resources.srcDir("src/main/assets")

    // Native dialogs/notifications can switch between English and Turkish
    // after installation, including while offline. Keep both on every device.
    bundle {
        language {
            enableSplit = false
        }
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.abrebostudio.consolegametranslator"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        buildConfigField("String", "PSN_BROKER_URL", "\"${if (psnBrokerOriginValid) psnBrokerOrigin else ""}\"")
        buildConfigField("String", "REVENUECAT_PUBLIC_KEY", quoted(revenueCatPublicKey))
        buildConfigField("String", "PRIVACY_POLICY_URL", quoted(privacyUrl))
        buildConfigField("String", "TERMS_OF_USE_URL", quoted(termsUrl))
        buildConfigField("String", "APP_CHECK_DEBUG_TOKEN", quoted(""))

        externalNativeBuild {
            cmake {
                arguments += listOf(
                    "-DCHIAKI_ENABLE_TESTS=OFF",
                    "-DCHIAKI_ENABLE_CLI=OFF",
                    "-DCHIAKI_ENABLE_GUI=OFF",
                    "-DCHIAKI_ENABLE_SETSU=OFF",
                    "-DCHIAKI_ENABLE_ANDROID=ON",
                    "-DCHIAKI_ENABLE_FFMPEG_DECODER=OFF",
                    "-DCHIAKI_ENABLE_PI_DECODER=OFF",
                    "-DCHIAKI_LIB_ENABLE_OPUS=OFF",
                    "-DCHIAKI_LIB_OPENSSL_EXTERNAL_PROJECT=ON",
                    "-DCHIAKI_LIB_JSONC_EXTERNAL_PROJECT=ON",
                    "-DCHIAKI_LIB_MINIUPNPC_EXTERNAL_PROJECT=ON",
                    "-DCHIAKI_ENABLE_STEAM_SHORTCUT=OFF",
                    "-DCHIAKI_ENABLE_STEAMDECK_NATIVE=OFF",
                    "-DANDROID_STL=c++_shared",
                    "-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON",
                    "-DCMAKE_SHARED_LINKER_FLAGS=-Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384"
                )
            }
        }
    }

    buildFeatures {
        prefab = true
        buildConfig = true
    }

    externalNativeBuild {
        cmake {
            path = file("../../chiaki-native/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    signingConfigs {
        if (!releaseKeys.getProperty("storeFile").isNullOrBlank()) create("release") {
            storeFile = rootProject.file(releaseKeys.getProperty("storeFile"))
            storePassword = releaseKeys.getProperty("storePassword")
            keyAlias = releaseKeys.getProperty("keyAlias")
            keyPassword = releaseKeys.getProperty("keyPassword")
        }
    }
    buildTypes {
        getByName("debug") {
            buildConfigField("String", "APP_CHECK_DEBUG_TOKEN", quoted(appCheckDebugProperties.getProperty("APP_CHECK_DEBUG_TOKEN", "")))
        }
        release {
            signingConfig = signingConfigs.findByName("release")
            proguardFiles("proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        freeCompilerArgs.add("-opt-in=kotlin.ExperimentalUnsignedTypes")
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation(platform("com.google.firebase:firebase-bom:35.1.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.revenuecat.purchases:purchases:11.0.0")
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20240303")
    androidTestImplementation("androidx.test:runner:1.6.1")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    implementation("com.google.oboe:oboe:1.10.0")
    // Bundle Latin OCR so recognition works offline without a Play Services model download.
    implementation("com.google.mlkit:text-recognition:16.0.1")
    // Translation models are downloaded on demand; English and Turkish are supported.
    implementation("com.google.mlkit:translate:17.0.3")
    // Keep the existing org.tensorflow.lite.Interpreter API for OPUS-MT.
    // The old tensorflow-lite:2.17.0 alias resolves to LiteRT 1.0.1, whose
    // prebuilt x86_64 JNI library is only 4 KB aligned. 1.4.2 aligns both 64-bit ABIs.
    implementation("com.google.ai.edge.litert:litert:1.4.2")
    implementation("com.google.code.gson:gson:2.11.0")
}

flutter {
    source = "../.."
}
