#!/bin/bash
# Note:   This script is used to build mlc for Android targets.
# Author: Stefanos Laskaridis (stefanos@brave.com)

# Exports
export CARGO_PATH=${CARGO_PATH:-"$HOME/.cargo/bin"}
export PATH="$CARGO_PATH:$PATH"
export JAVA_HOME=${JAVA_HOME:-"/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"}
export TVM_HOME=${TVM_HOME:-"$PWD/../../tvm-unity/"}
export MLC_HOME=${MLC_HOME:-"$PWD/../"}
export TVM_NDK_CC=${TVM_NDK_CC:-"$HOME/Library/Android/sdk/ndk/25.2.9519653/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android24-clang"}
export ANDROID_NDK=${ANDROID_NDK:-"$HOME/Library/Android/sdk/ndk/25.2.9519653/"}

BENCHMARK_PER_LAYER=${BENCHMARK_PER_LAYER:-0}

build_android() {
    echo "Preparing android libs"
    pushd android/library/
    BENCHMARK_PER_LAYER=${BENCHMARK_PER_LAYER} ./prepare_libs.sh
    popd
}

cd $MLC_HOME
build_android
