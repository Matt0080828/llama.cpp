# CMake toolchain file for OpenWrt T830 (MT7992, aarch64, musl) cross builds.
#
# Usage (standalone, outside OpenWrt):
#   cmake -B build -DCMAKE_TOOLCHAIN_FILE=cmake/openwrt-t830.cmake \
#         -DCMAKE_C_COMPILER=$SDK/staging_dir/.../aarch64-openwrt-linux-musl-gcc \
#         -DCMAKE_CXX_COMPILER=$SDK/staging_dir/.../aarch64-openwrt-linux-musl-g++ \
#         ...
#
# Inside an OpenWrt build (include/cmake.mk) the toolchain file is generated
# by OpenWrt itself; this file is for manual / CI builds and pins the same
# options. See docs/openwrt.md.
#
# Notes:
#   - CMAKE_CROSSCOMPILING will be set, so ggml auto-disables GGML_NATIVE
#     (no -march=native probing of the build host).
#   - No GPU/CUDA/Vulkan/Metal/SYCL/RPC/OpenVINO/Kompute — CPU + NEON only.
#   - musl target: do NOT enable LLAMA_OPENSSL unless libssl is in the rootfs
#     (the T830 HH20C tree has no libssl package).
#   - C++17 is required (ggml sets CMAKE_CXX_STANDARD 17).

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# Compilers: use env CC/CXX if provided (OpenWrt style), else these names.
if (NOT DEFINED ENV{CC} AND NOT DEFINED CMAKE_C_COMPILER)
  set(CMAKE_C_COMPILER aarch64-openwrt-linux-musl-gcc)
endif()
if (NOT DEFINED ENV{CXX} AND NOT DEFINED CMAKE_CXX_COMPILER)
  set(CMAKE_CXX_COMPILER aarch64-openwrt-linux-musl-g++)
endif()

# Search paths: only inside the target sysroot.
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# CPU-only. NEON is in the aarch64 baseline; GGML_USE_CPU_AARCH64 is enabled
# automatically for aarch64 targets.
set(GGML_NATIVE OFF        CACHE BOOL "" FORCE)
set(GGML_CUDA    OFF       CACHE BOOL "" FORCE)
set(GGML_VULKAN  OFF       CACHE BOOL "" FORCE)
set(GGML_METAL   OFF       CACHE BOOL "" FORCE)
set(GGML_SYCL    OFF       CACHE BOOL "" FORCE)
set(GGML_RPC     OFF       CACHE BOOL "" FORCE)
set(GGML_OPENVINO OFF      CACHE BOOL "" FORCE)
set(GGML_KOMPUTE OFF       CACHE BOOL "" FORCE)
set(GGML_VXE     OFF       CACHE BOOL "" FORCE)
set(GGML_BLAS    OFF       CACHE BOOL "" FORCE)
set(GGML_LLAMAFILE OFF     CACHE BOOL "" FORCE)
set(LLAMA_OPENSSL OFF      CACHE BOOL "" FORCE)

# Release build, static final binaries, no examples/tests.
set(CMAKE_BUILD_TYPE Release        CACHE STRING "" FORCE)
set(BUILD_SHARED_LIBS OFF           CACHE BOOL "" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF        CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TESTS    OFF        CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TOOLS    ON         CACHE BOOL "" FORCE)
set(LLAMA_BUILD_SERVER   ON         CACHE BOOL "" FORCE)
set(LLAMA_BUILD_APP      OFF        CACHE BOOL "" FORCE)
set(LLAMA_BUILD_UI       OFF        CACHE BOOL "" FORCE)
set(LLAMA_USE_PREBUILT_UI OFF       CACHE BOOL "" FORCE)
