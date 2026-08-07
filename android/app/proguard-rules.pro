# Keep rules for release (R8).

# Flutter registers plugins via reflection on GeneratedPluginRegistrant;
# without these keeps R8 strips it and NO plugin works in release.
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.engine.plugins.** { *; }

# flutter_local_notifications uses Gson reflection for scheduled payloads.
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type

# Play Core is referenced by Flutter's deferred components but unused here.
-dontwarn com.google.android.play.core.**
