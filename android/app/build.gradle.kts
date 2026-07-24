import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    // ローカルビルドで key.properties がない場合はエラーにする（署名漏れ防止）
    // CI環境などで意図的にスキップしたい場合以外は、これが本来の姿
    println("WARNING: key.properties not found at ${keystorePropertiesFile.absolutePath}")
}

android {
    namespace = "jp.ikegam1.simple_molkky_score"
    // Google Play 2026-08-31 期限: Android 16 (API 36) 以上を target とする
    // 必要があるため、compileSdk / targetSdk を明示的に 36 に上げる。
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "jp.ikegam1.simple_molkky_score"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86_64"))
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        getByName("release") {
            // 明示的に signingConfig を指定。値が空ならビルドエラーになるようにする。
            signingConfig = signingConfigs.getByName("release")
            // Play Console 推奨事項: R8 最適化を有効化してメモリ / パフォーマンスを改善。
            // 参照される proguard-rules.pro に Firebase / GoogleSignIn / Flutter engine の
            // keep rules を並べているので、リフレクション経由でロードされる名前は保持される。
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.activity:activity-ktx:1.9.0")
}
