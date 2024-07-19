#!/bin/bash
# Note:   This script is used to build mlc for local and Jetson targets.
# Author: Stefanos Laskaridis (stefanos@brave.com)

# Exports
export CARGO_PATH=${CARGO_PATH:-"$HOME/.cargo/bin"}
export PATH="$CARGO_PATH:$PATH"
export JAVA_HOME=${JAVA_HOME:-"/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"}
export TVM_HOME=${TVM_HOME:-"$PWD/../../tvm-unity/"}
export MLC_HOME=${MLC_HOME:-"$PWD/../"}
export BENCHMARK_PER_LAYER=${BENCHMARK_PER_LAYER:-"0"}
if [[ $(uname -r) == *tegra ]]; then
    export IS_JETSON="1"
else
    export IS_JETSON="0"
fi

configure_cmake() {
    echo "Configuring cmake"
    rm -rf build
    mkdir -p build;

    pushd build/
    touch config.cmake
    echo "set(TVM_HOME $TVM_HOME)" >> config.cmake
    echo "set(CMAKE_BUILD_TYPE RelWithDebInfo)" >> config.cmake
    echo "set(USE_VULKAN OFF)" >> config.cmake
    if [ "$IS_JETSON" == "1" ]; then
        echo "set(CMAKE_CXX_STANDARD 17)" >> config.cmake
        echo "set(CMAKE_CUDA_STANDARD 17)" >> config.cmake
        echo "set(CMAKE_CUDA_ARCHITECTURES \"72;87\")" >> config.cmake
        echo "set(USE_CUDA ON)" >> config.cmake
        echo "set(USE_CUDNN ON)" >> config.cmake
        echo "set(USE_CUBLAS ON)" >> config.cmake
        echo "set(USE_CURAND ON)" >> config.cmake
        echo "set(USE_CUTLASS ON)" >> config.cmake
        echo "set(USE_THRUST ON)" >> config.cmake
        echo "set(USE_GRAPH_EXECUTOR_CUDA_GRAPH ON)" >> config.cmake
        echo "set(USE_STACKVM_RUNTIME ON)" >> config.cmake
        echo "set(USE_LLVM \"/usr/bin/llvm-config --link-static\")" >> config.cmake
        echo "set(HIDE_PRIVATE_SYMBOLS ON)" >> config.cmake
        echo "set(SUMMARIZE ON)" >> config.cmake
    else
        echo "set(USE_CUDA   OFF)" >> config.cmake
        echo "set(USE_METAL  ON)" >> config.cmake
        echo "set(USE_OPENCL ON)" >> config.cmake
    fi
    popd
}

build() {
    echo "Building MLC"
    pushd build/
    if [ "$BENCHMARK_PER_LAYER" == "1" ]; then
        echo "Building with benchmark per layer"
        cmake -DBENCHMARK_PER_LAYER=1 .. && cmake --build . --parallel 8
    else
        echo "Building without benchmark per layer"
        cmake .. && cmake --build . --parallel 8
    fi
    popd
}

# Install python
install_python_package() {
    echo "Installing python package"
    pushd python
    pip install -e .
    popd
}

cd $MLC_HOME
configure_cmake && \
build && \
install_python_package
