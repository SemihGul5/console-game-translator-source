#include <jni.h>

#include <algorithm>
#include <memory>
#include <stdexcept>
#include <string>
#include <thread>
#include <vector>

#include "ctranslate2/translator.h"

namespace {
struct HpltEngine {
  ctranslate2::Translator translator;

  HpltEngine(const std::string& model_directory, size_t thread_count)
      : translator(model_directory,
                   ctranslate2::Device::CPU,
                   ctranslate2::ComputeType::DEFAULT,
                   {0},
                   false,
                   ctranslate2::ReplicaPoolConfig{thread_count, 0, -1}) {}
};

std::string read_string(JNIEnv* env, jstring value) {
  if (value == nullptr)
    throw std::invalid_argument("Model yolu boş.");
  const char* chars = env->GetStringUTFChars(value, nullptr);
  if (chars == nullptr)
    throw std::runtime_error("Metin JNI'den okunamadı.");
  std::string result(chars);
  env->ReleaseStringUTFChars(value, chars);
  return result;
}

void throw_java(JNIEnv* env, const char* message) {
  jclass exception_class = env->FindClass("java/lang/IllegalStateException");
  if (exception_class != nullptr)
    env->ThrowNew(exception_class, message);
}
}  // namespace

extern "C" JNIEXPORT jlong JNICALL
Java_com_abrebostudio_consolegametranslator_HpltCTranslate2_nativeCreate(
    JNIEnv* env, jclass, jstring model_directory, jint thread_count) {
  try {
    const size_t threads = static_cast<size_t>(std::max(1, thread_count));
    return reinterpret_cast<jlong>(
        new HpltEngine(read_string(env, model_directory), threads));
  } catch (const std::exception& error) {
    throw_java(env, error.what());
  } catch (...) {
    throw_java(env, "HPLT modeli açılamadı.");
  }
  return 0;
}

extern "C" JNIEXPORT jobjectArray JNICALL
Java_com_abrebostudio_consolegametranslator_HpltCTranslate2_nativeTranslate(
    JNIEnv* env, jclass, jlong handle, jobjectArray source_tokens) {
  try {
    if (handle == 0 || source_tokens == nullptr)
      throw std::invalid_argument("Çeviri girdisi geçersiz.");

    std::vector<std::string> tokens;
    const jsize token_count = env->GetArrayLength(source_tokens);
    tokens.reserve(static_cast<size_t>(token_count));
    for (jsize index = 0; index < token_count; ++index) {
      auto token = static_cast<jstring>(env->GetObjectArrayElement(source_tokens, index));
      tokens.emplace_back(read_string(env, token));
      env->DeleteLocalRef(token);
    }

    ctranslate2::TranslationOptions options;
    options.beam_size = 4;
    options.max_decoding_length = 256;
    auto* engine = reinterpret_cast<HpltEngine*>(handle);
    const auto translated = engine->translator.translate_batch({tokens}, options, 1);
    const auto& result_tokens = translated.at(0).hypotheses.at(0);

    jclass string_class = env->FindClass("java/lang/String");
    jobjectArray result = env->NewObjectArray(
        static_cast<jsize>(result_tokens.size()), string_class, nullptr);
    for (size_t index = 0; index < result_tokens.size(); ++index) {
      jstring token = env->NewStringUTF(result_tokens[index].c_str());
      env->SetObjectArrayElement(result, static_cast<jsize>(index), token);
      env->DeleteLocalRef(token);
    }
    return result;
  } catch (const std::exception& error) {
    throw_java(env, error.what());
  } catch (...) {
    throw_java(env, "HPLT çevirisi tamamlanamadı.");
  }
  return nullptr;
}

extern "C" JNIEXPORT void JNICALL
Java_com_abrebostudio_consolegametranslator_HpltCTranslate2_nativeDestroy(
    JNIEnv*, jclass, jlong handle) {
  delete reinterpret_cast<HpltEngine*>(handle);
}


