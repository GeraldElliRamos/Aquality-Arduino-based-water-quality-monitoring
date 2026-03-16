plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") apply true
}




android {
    namespace = "com.example.aquality_arduino_based_water_quality_monitoring"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.aquality_arduino_based_water_quality_monitoring"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}



dependencies {
  // Import the Firebase BoM
  implementation(platform("com.google.firebase:firebase-bom:34.10.0"))

    // Enable core library desugaring for libraries that require newer Java APIs
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")


  // TODO: Add the dependencies for Firebase products you want to use
  // When using the BoM, don't specify versions in Firebase dependencies
  implementation("com.google.firebase:firebase-analytics")
  implementation("com.google.firebase:firebase-auth")
  implementation("com.google.firebase:firebase-firestore")
  implementation("com.google.firebase:firebase-database")

  // implementation(platform("com.google.firebase:firebase-bom:34.10.0"))
  // implementation("com.google.android.gms:play-services-auth:21.5.1")


  // Add the dependencies for any other desired Firebase products
  // https://firebase.google.com/docs/android/setup#available-libraries
  // https://firebase.google.com/docs/auth/android/email-link-auth?authuser=0&_gl=1*bkgirx*_ga*MTY4ODE0NDQ1OS4xNzczNTc2NDU2*_ga_CW55HF8NVT*czE3NzM1NzY0NTYkbzEkZzEkdDE3NzM1NzgzNzIkajEzJGwwJGgw
}
