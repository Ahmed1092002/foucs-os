# Focus OS — Build Workaround for Windows Gradle Kotlin Cache Bug

## Issue
The `shared_preferences_android` Kotlin plugin has a known incremental compilation cache corruption bug on Windows (AGP 9.x + Kotlin 2.x). The error:
```
Could not close incremental caches in .../shared_preferences_android/kotlin/compileReleaseKotlin/...class-fq-name-to-source.tab
```

## Workaround (pick one)

### Option A: Disable incremental for the problematic plugin (recommended)
Add to `android/build.gradle.kts`:
```kotlin
subprojects {
    afterEvaluate {
        if (name == "shared_preferences_android") {
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                // Note: isIncremental property not available on new DSL; use freeCompilerArgs instead
                kotlinOptions {
                    freeCompilerArgs = listOf("-Xno-inline", "-Xno-optimization")
                }
            }
        }
    }
}
```

### Option B: Global Gradle property (already in gradle.properties)
```properties
org.gradle.jvmargs=... -Dkotlin.incremental=false -Dkotlin.incremental.useClasspathSnapshot=false
```

### Option C: Build via CI (Linux runners don't have this issue)
GitHub Actions / GitLab CI / Codemagic build cleanly.

## Status
- Debug builds on Windows: ❌ blocked by this bug
- Release APK/AAB on Windows: ❌ blocked
- Release APK/AAB on CI (Ubuntu): ✅ works

## Next Steps
1. File a Flutter issue if not already tracked
2. Wait for `shared_preferences` plugin update (v2.5.6+) that bumps Kotlin
3. Or migrate to `flutter_secure_storage` for persistence (already used for tokens) and drop `shared_preferences` entirely

For now, **CI builds are the production path**.