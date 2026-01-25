-keep class **.zego.** { *; }

# Razorpay Proguard Rules
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}
-optimizations !method/inlining/
-keepclasseswithmembers class * {
 public void onPayment*(...);
}
