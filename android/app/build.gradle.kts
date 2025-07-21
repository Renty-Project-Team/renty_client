import java.util.Properties
import java.io.FileInputStream

// keystoreProperties를 최상단에 두는 것이 좋습니다.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("app/key.properties") // 문자열은 큰따옴표 사용 권장
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { fis -> // try-with-resources 와 유사
        keystoreProperties.load(fis)
    }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.renty_client"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.renty_client"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") { // KTS에서는 create 또는 getByName 등을 사용합니다.
            // 속성 값 가져오기: getProperty 사용
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            // storeFile 경로가 null일 수 있으므로 안전 호출 및 let 사용
            keystoreProperties.getProperty("storeFile")?.let {
                storeFile = project.file(it) // project.file() 또는 rootProject.file() 사용
            }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        getByName("release") { // 이미 생성된 설정을 가져올 때는 getByName
            // signingConfig에 위에서 만든 release 설정을 할당
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}