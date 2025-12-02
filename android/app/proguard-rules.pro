-ignorewarnings
-keep class * {
    public private *;
}
-dontwarn org.xmlpull.v1.XmlPullParser
-dontwarn org.xmlpull.v1.XmlSerializer
-keep class org.xmlpull.v1.* {*;}

# Keep native methods and JNI classes to prevent SIGSEGV crashes
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Google ML Kit classes
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**

# Keep camera and barcode scanner classes
-keep class com.google.zxing.** { *; }
-keep class me.dm7.barcodescanner.** { *; }
-dontwarn com.google.zxing.**
-dontwarn me.dm7.barcodescanner.**

# Keep biometric authentication classes
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**

# Keep image processing classes
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

# Prevent obfuscation of Flutter engine classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**