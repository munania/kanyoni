# jaudiotagger creates tag frames/readers by class name.
-keep class org.jaudiotagger.** { *; }
-dontwarn org.jaudiotagger.**
# Desktop-only classes it can reference but never uses on Android.
-dontwarn java.awt.**
-dontwarn javax.imageio.**
-dontwarn javax.swing.**
