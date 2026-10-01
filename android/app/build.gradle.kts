import com.google.firebase.crashlytics.buildtools.gradle.CrashlyticsExtension
import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing (PRD 11.1: signed App Bundles). android/key.properties is
// written by the release workflow from secrets and never committed; without
// it, release builds use the debug key so size checks still run.
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "lk.shopcompanion.shop_companion"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "lk.shopcompanion.shop_companion"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // PRD 2: Android 8.0 (API 26) on 2 GB Android Go phones.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildFeatures {
        resValues = true
    }

    // PRD 11.1: separate Firebase projects for dev, staging and production.
    // `inviteHost` is the Firebase Hosting domain that serves /invite/{token}.
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Shop Companion Dev")
            manifestPlaceholders["inviteHost"] = "shop-companion-dev.web.app"
        }
        create("staging") {
            dimension = "env"
            applicationIdSuffix = ".staging"
            resValue("string", "app_name", "Shop Companion Staging")
            manifestPlaceholders["inviteHost"] = "shop-companion-staging.web.app"
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Shop Companion")
            manifestPlaceholders["inviteHost"] = "shop-companion-prod.web.app"
        }
    }

    signingConfigs {
        if (keyProperties.isNotEmpty()) {
            create("upload") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("upload")
                ?: signingConfigs.getByName("debug")
            // R8 mapping files go up from CI with the Firebase CLI; the app
            // has no google-services.json for the plugin's own upload.
            configure<CrashlyticsExtension> {
                mappingFileUploadEnabled = false
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // local_auth needs an AppCompat launch theme (FlutterFragmentActivity).
    implementation("androidx.appcompat:appcompat:1.7.1")
}
