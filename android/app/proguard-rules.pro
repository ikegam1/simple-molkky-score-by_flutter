# Play Console 推奨事項 (R8 最適化) を有効にするための keep rules。
# Flutter default (proguard-android-optimize.txt) と各ライブラリの
# consumer-rules で大半カバーされるが、リフレクション経由で参照
# されるクラスは明示的に keep する必要がある。

# --- Flutter / Dart 側で必要な keep ---
# Flutter engine ↔ Dart 間の platform channel で参照される名前を
# 保持 (デフォルトの proguard-android-optimize.txt にも含まれるが
# 念のため明示)。
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-dontwarn io.flutter.embedding.**

# --- Firebase / Google Play Services ---
# Firestore / Auth / Core は @Keep annotation を使うので大半は
# consumer-rules で守られるが、リフレクション経由の TypeToken 系
# を明示 keep。
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**

# --- Google Sign-In ---
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# --- kotlinx.coroutines (Firebase 依存) ---
-dontwarn kotlinx.coroutines.**
-keep class kotlinx.coroutines.** { *; }

# --- AndroidX Lifecycle / Activity ---
# enableEdgeToEdge に使う androidx.activity クラスは keep されるが
# 念のため。
-keep class androidx.activity.ComponentActivity { *; }

# --- 標準的な attribute 保持 ---
# ジェネリック / インナークラス / アノテーション / ソース情報を
# 残すことでスタックトレース調査が可能になる。
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes SourceFile,LineNumberTable

# --- 反射 API で使われる Missing rules 警告の抑制 ---
# javax / java.awt など Android 未提供の依存は Play Services 経由で
# 引き込まれることがあるので dontwarn しておく。
-dontwarn javax.**
-dontwarn java.awt.**

# --- WebView JS interface (念のため) ---
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
