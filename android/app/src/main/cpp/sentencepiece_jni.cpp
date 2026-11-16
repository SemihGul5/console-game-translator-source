#include <jni.h>
#include <map>
#include <mutex>
#include <string>
#include <vector>
#include "sentencepiece_processor.h"

using sentencepiece::SentencePieceProcessor;
static std::map<jlong, SentencePieceProcessor*> processors;
static std::mutex processorsMutex;
static jlong nextHandle = 1;
static SentencePieceProcessor* getProcessor(jlong handle) {
  std::lock_guard<std::mutex> lock(processorsMutex);
  auto it = processors.find(handle);
  return it == processors.end() ? nullptr : it->second;
}

extern "C" JNIEXPORT jlong JNICALL
Java_com_abrebostudio_consolegametranslator_SentencePieceTokenizer_nativeCreate(JNIEnv* env, jobject, jstring path) {
  const char* chars = env->GetStringUTFChars(path, nullptr);
  auto* processor = new SentencePieceProcessor();
  auto status = processor->Load(chars);
  env->ReleaseStringUTFChars(path, chars);
  if (!status.ok()) { delete processor; return 0; }
  std::lock_guard<std::mutex> lock(processorsMutex);
  const jlong handle = nextHandle++;
  processors[handle] = processor;
  return handle;
}
extern "C" JNIEXPORT void JNICALL
Java_com_abrebostudio_consolegametranslator_SentencePieceTokenizer_nativeDestroy(JNIEnv*, jobject, jlong handle) {
  std::lock_guard<std::mutex> lock(processorsMutex);
  auto it = processors.find(handle);
  if (it != processors.end()) { delete it->second; processors.erase(it); }
}
extern "C" JNIEXPORT jobjectArray JNICALL
Java_com_abrebostudio_consolegametranslator_SentencePieceTokenizer_nativeEncode(JNIEnv* env, jobject, jlong handle, jstring input) {
  auto* processor = getProcessor(handle);
  jclass stringClass = env->FindClass("java/lang/String");
  if (!processor) return env->NewObjectArray(0, stringClass, nullptr);
  const char* chars = env->GetStringUTFChars(input, nullptr);
  std::vector<std::string> pieces;
  processor->Encode(chars, &pieces);
  env->ReleaseStringUTFChars(input, chars);
  jobjectArray result = env->NewObjectArray(static_cast<jsize>(pieces.size()), stringClass, nullptr);
  for (jsize i = 0; i < static_cast<jsize>(pieces.size()); ++i)
    env->SetObjectArrayElement(result, i, env->NewStringUTF(pieces[i].c_str()));
  return result;
}
extern "C" JNIEXPORT jstring JNICALL
Java_com_abrebostudio_consolegametranslator_SentencePieceTokenizer_nativeDecode(JNIEnv* env, jobject, jlong handle, jobjectArray input) {
  auto* processor = getProcessor(handle);
  if (!processor) return env->NewStringUTF("");
  const jsize count = env->GetArrayLength(input);
  std::vector<std::string> pieces;
  for (jsize i = 0; i < count; ++i) {
    auto item = static_cast<jstring>(env->GetObjectArrayElement(input, i));
    const char* chars = env->GetStringUTFChars(item, nullptr);
    pieces.emplace_back(chars);
    env->ReleaseStringUTFChars(item, chars);
    env->DeleteLocalRef(item);
  }
  std::string decoded;
  processor->Decode(pieces, &decoded);
  return env->NewStringUTF(decoded.c_str());
}
