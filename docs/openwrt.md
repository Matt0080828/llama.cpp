# OpenWrt build (T830 / MT7992, aarch64 musl)

This branch adds everything needed to build llama.cpp into an OpenWrt image
for the Askey T830 CPE (NCM1000C3 / HH20C, FG370 SDK).

## What was added (vs. master)

- `cmake/openwrt-t830.cmake` — toolchain file: aarch64/musl cross, CPU+NEON
  only, all GPU backends forced OFF, OpenSSL OFF (no libssl in that rootfs),
  Release/static/server+tools only.
- `CMakePresets.json` — preset `openwrt-t830` for one-command local configure.
- `docs/openwrt.md` (this file).

Master's CMake already handles `CMAKE_CROSSCOMPILING` (auto-disables
`GGML_NATIVE`). The FG370/T830 prebuilt toolchain is **GCC 9.3.0**, which
lacks `vld1q_s8_x4` / `vld1q_u8_x4`; `ggml/src/ggml-cpu/ggml-cpu-impl.h`
composes those loads for GCC < 10. CMake 3.22 cannot read `CMakePresets.json`
version 4 — pass `-DCMAKE_TOOLCHAIN_FILE=cmake/openwrt-t830.cmake` instead.

## OpenWrt package integration

The package lives outside this repo (Askey SDK custom package tree):

```
askey_codebases/product/ee_sw_for_ncm1000c3/cust/openwrt/package/askey/llama-cpp/
```

Its Makefile uses OpenWrt's standard cmake integration:

```make
include $(INCLUDE_DIR)/cmake.mk

CMAKE_OPTIONS += \
	-DCMAKE_BUILD_TYPE=Release \
	-DBUILD_SHARED_LIBS=OFF \
	-DGGML_NATIVE=OFF \
	-DGGML_CUDA=OFF -DGGML_VULKAN=OFF -DGGML_METAL=OFF \
	-DGGML_SYCL=OFF -DGGML_RPC=OFF -DGGML_OPENVINO=OFF \
	-DGGML_KOMPUTE=OFF -DGGML_VXE=OFF -DGGML_BLAS=OFF \
	-DLLAMA_OPENSSL=OFF \
	-DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF \
	-DLLAMA_BUILD_TOOLS=ON -DLLAMA_BUILD_SERVER=ON
```

OpenWrt's `include/cmake.mk` auto-generates the cross toolchain file and
installs a host cmake if the tree has none.

## Host cross-build (FG370 SDK, GCC 9.3)

Verified on Ubuntu 22.04 host cmake 3.22.1 against the Fibocom FG370 /
Askey T830 SDK prebuilt toolchain:

`mtk/prebuilt/openwrt-toolchain/arm64-a55_neon-gcc-9.3.0_musl`

(extracted from `mtk_src/mtk-ea23b8b.tar.gz`). CMake 3.22 cannot read
`CMakePresets.json` version 4, so pass the toolchain file by hand.

```bash
# point TC at the unpacked toolchain root (contains bin/ and lib/)
TC=/path/to/arm64-a55_neon-gcc-9.3.0_musl
export STAGING_DIR="$TC"
export PATH="$TC/bin:$PATH"

cmake -S . -B build-openwrt-t830 \
  -G "Unix Makefiles" \
  -DCMAKE_TOOLCHAIN_FILE=cmake/openwrt-t830.cmake \
  -DCMAKE_C_COMPILER="$TC/bin/aarch64-openwrt-linux-musl-gcc" \
  -DCMAKE_CXX_COMPILER="$TC/bin/aarch64-openwrt-linux-musl-g++" \
  -DCMAKE_FIND_ROOT_PATH="$TC"

cmake --build build-openwrt-t830 -j"$(nproc)" --target llama-cli llama-server
file build-openwrt-t830/bin/llama-cli build-openwrt-t830/bin/llama-server
```

Expected:

```text
ELF 64-bit LSB executable, ARM aarch64
interpreter: /lib/ld-musl-aarch64.so.1
NEEDED: libstdc++.so.6, libgcc_s.so.1, libc.so
```

These are **not** fully static. On the T830 rootfs the loader is
`/lib/ld-musl-aarch64.so.1`. The matching host copy lives at
`$TC/lib/ld-musl-aarch64.so.1`. The device also needs `libstdc++.so.6`,
`libgcc_s.so.1`, and musl `libc.so` (OpenWrt already ships musl).

Host RPATH baked into the ELF points at `$TC/lib` and is unused on device.

## Prerequisites on the SDK

- GCC 9.3.0 aarch64 musl (`aarch64-openwrt-linux-musl-g++`); C++17 is OK
- musl C++ runtime on the target (`libstdc++.so.6` / `libgcc_s.so.1`)

## Model

- `functiongemma-270m-it` Q4_K_M (~200 MB, GGUF, Gemma2 arch — supported).
- Served by `llama-server` on 127.0.0.1:8080 (OpenAI-compatible), context 2048.

## RAM budget (T830 has ~1.65 GB measured)

| item | size |
|------|------|
| system + WiFi7/5G/mesh | ~1 GB |
| FunctionGemma-270M Q4 + KV(2K) | ~300 MB |
| hermes-agent venv | ~300 MB |
| **peak** | **~1.6 GB** — tight; run llama-server on demand |
