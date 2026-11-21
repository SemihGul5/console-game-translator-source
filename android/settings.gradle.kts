pluginManagement {
    val flutterSdkPath =
        run {
            // Flutter can regenerate unescaped uppercase Windows drive colons.
            // Normalize only SDK paths before Gradle/lint read this generated file.
            val localPropertiesFile = file("local.properties")
            val original = localPropertiesFile.readText()
            val escaped = original.replace(
                Regex("(?m)^((?:sdk\\.dir|flutter\\.sdk)\\s*=\\s*[A-Za-z]):")
            ) { "${it.groupValues[1]}\\:" }
            if (escaped != original) localPropertiesFile.writeText(escaped)
            val properties = java.util.Properties()
            localPropertiesFile.inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.4.21" apply false
    id("com.google.gms.google-services") version "4.4.4" apply false
}

include(":app")
