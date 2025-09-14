# Flutter'ın varsayılan kuralları (Genellikle zaten vardır ama eklemek güvenlidir)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# mobile_scanner paketinin çökmesini engellemek için GEREKLİDİR.
-keep class dev.steenbakker.mobile_scanner.** { *; }
-keep class com.google.mlkit.vision.barcode.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }

# cached_network_image paketi için
-dontwarn com.bumptech.glide.**
-keep class com.bumptech.glide.** { *; }
-keep public class * extends com.bumptech.glide.module.AppGlideModule
-keep class * implements com.bumptech.glide.module.GlideModule

# http paketi için genellikle gerekmez ama eklemek güvenlidir
-dontwarn okio.**
-dontwarn org.conscrypt.**
-dontwarn com.google.android.play.core.**
