cmake_minimum_required(VERSION 3.22.1)
project(sentencepiece_jni)

include(FetchContent)
FetchContent_Declare(sentencepiece
  GIT_REPOSITORY https://github.com/google/sentencepiece.git
  GIT_TAG v0.2.0)
FetchContent_GetProperties(sentencepiece)
if(NOT sentencepiece_POPULATED)
  FetchContent_Populate(sentencepiece)
  add_subdirectory(${sentencepiece_SOURCE_DIR} ${sentencepiece_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()

add_library(sentencepiece_jni SHARED sentencepiece_jni.cpp)
target_include_directories(sentencepiece_jni PRIVATE ${sentencepiece_SOURCE_DIR}/src)
target_link_libraries(sentencepiece_jni PRIVATE sentencepiece-static log)

# CTranslate2 currently supports the HPLT package on 64-bit ARM Android.
# Keep the existing 32-bit app ABI buildable without its optional Model C JNI.
if(CMAKE_ANDROID_ARCH_ABI STREQUAL "arm64-v8a")
  # Keep the upstream revision fixed so native builds and downloaded model metadata agree.
  set(BUILD_CLI OFF CACHE BOOL "" FORCE)
  set(BUILD_TESTS OFF CACHE BOOL "" FORCE)
  set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
  set(OPENMP_RUNTIME NONE CACHE STRING "" FORCE)
  set(CMAKE_POSITION_INDEPENDENT_CODE ON)
  set(WITH_MKL OFF CACHE BOOL "" FORCE)
  set(WITH_DNNL OFF CACHE BOOL "" FORCE)
  set(WITH_ACCELERATE OFF CACHE BOOL "" FORCE)
  set(WITH_OPENBLAS OFF CACHE BOOL "" FORCE)
  set(WITH_RUY ON CACHE BOOL "" FORCE)
  set(WITH_CUDA OFF CACHE BOOL "" FORCE)
  set(WITH_HIP OFF CACHE BOOL "" FORCE)
  set(ENABLE_CPU_DISPATCH OFF CACHE BOOL "" FORCE)
  FetchContent_Declare(ctranslate2
    GIT_REPOSITORY https://github.com/OpenNMT/CTranslate2.git
    GIT_TAG 5de572ef60b67a0276c5989ee73d0072808ff4c3
    GIT_SUBMODULES
      third_party/spdlog
      third_party/ruy
    GIT_SUBMODULES_RECURSE TRUE)
  FetchContent_MakeAvailable(ctranslate2)
  set_target_properties(ctranslate2 PROPERTIES POSITION_INDEPENDENT_CODE ON)

  # Android debug variants otherwise compile CTranslate2 and Ruy without any
  # optimizer, making the HPLT model dramatically slower during device use.
  # Optimize only these HPLT inference targets; keep the rest of the app debuggable.
  target_compile_options(ctranslate2 PRIVATE
    "$<$<CONFIG:Debug>:-O3>"
    "$<$<CONFIG:Debug>:-DNDEBUG>")
  get_property(_ct2_ruy_targets
    DIRECTORY "${ctranslate2_SOURCE_DIR}/third_party/ruy/ruy"
    PROPERTY BUILDSYSTEM_TARGETS)
  foreach(_ct2_ruy_target IN LISTS _ct2_ruy_targets)
    get_target_property(_ct2_ruy_type "${_ct2_ruy_target}" TYPE)
    if(NOT _ct2_ruy_type STREQUAL "INTERFACE_LIBRARY")
      target_compile_options("${_ct2_ruy_target}" PRIVATE
        "$<$<CONFIG:Debug>:-O3>"
        "$<$<CONFIG:Debug>:-DNDEBUG>")
    endif()
  endforeach()

# CTranslate2's Linux affinity helper calls pthread_setaffinity_np, which the
# Android NDK does not expose. Model workers use the default unpinned core path.
  if(ANDROID)
    set(_ct2_thread_pool "${ctranslate2_SOURCE_DIR}/src/thread_pool.cc")
    file(READ "${_ct2_thread_pool}" _ct2_thread_pool_source)
    string(REPLACE
      "#if !defined(__linux__) || defined(_OPENMP)"
      "#if !defined(__linux__) || defined(_OPENMP) || defined(__ANDROID__)"
      _ct2_thread_pool_source "${_ct2_thread_pool_source}")
    file(WRITE "${_ct2_thread_pool}" "${_ct2_thread_pool_source}")
  endif()

  add_library(hplt_ctranslate2_jni SHARED hplt_ctranslate2_jni.cpp)
  target_compile_features(hplt_ctranslate2_jni PRIVATE cxx_std_17)
  target_link_libraries(hplt_ctranslate2_jni PRIVATE ctranslate2 log)
endif()
