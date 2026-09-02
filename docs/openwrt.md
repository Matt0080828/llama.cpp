# OpenWrt build (T830 / MT7992, aarch64 musl)

This branch adds everything needed to build llama.cpp into an OpenWrt image
for the Askey T830 CPE (NCM1000C3 / HH20C, FG370 SDK).

## What was added (vs. master)

- `cmake/openwrt-t830.cmake` — toolchain file: aarch64/musl cross, CPU+NEON
  only, all GPU backends forced OFF, OpenSSL OFF (no libssl in that rootfs),
  Release/static/server+tools only.
- `CMakePresets.json` — preset `openwrt-t830` for one-command local configure.
- `docs/openwrt.md` (this file).

The code itself is unchanged — master's CMake already handles
`CMAKE_CROSSCOMPILING` (auto-disables `GGML_NATIVE`), so no source patch is
required.

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

## Prerequisites on the SDK

- target C++17-capable cross g++ (T830 toolchain is gcc 12 class — OK)
- C++ runtime for musl (uclibc++/libstdc++ in the SDK — the tree ships
  `package/libs/uclibc++`; set `DEPENDS:=+uclibc++` in the package if the
  binaries dynamically link it)

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
