# chiaki-jni.c resolves the Kotlin bridge by literal class/member names through
# FindClass, GetFieldID and GetMethodID. R8 cannot see those native references.
# Keep the entire small JNI bridge, including private callbacks, constructors,
# enum constants and Kotlin object INSTANCE fields used by discovery, pairing
# and streaming. Keeping only native methods does not preserve these upcalls.
-keep class com.metallic.chiaki.lib.** { *; }
