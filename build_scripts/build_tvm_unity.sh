#!/bin/bash
# Note:   This script is used to build tvm unity backend for running MLC.
# Author: Stefanos Laskaridis (stefanos@brave.com)


# Exports
export CARGO_PATH=${CARGO_PATH:-"$HOME/.cargo/bin"}
export PATH="$CARGO_PATH:$PATH"
export JAVA_HOME=${JAVA_HOME:-"/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"}
export TVM_HOME=${TVM_HOME:-"../../tvm-unity"}
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
    cp ../cmake/config.cmake .

    echo "set(CMAKE_BUILD_TYPE RelWithDebInfo)" >> config.cmake
    echo "set(USE_LLVM \"llvm-config --ignore-libllvm --link-static\")" >> config.cmake
    echo "set(HIDE_PRIVATE_SYMBOLS ON)" >> config.cmake
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
        echo "set(USE_VULKAN OFF)" >> config.cmake
        echo "set(USE_OPENCL ON)" >> config.cmake
    fi
    popd
}

build() {
    echo "Building TVM Unity"
    pushd build/
    cmake .. && cmake --build . --parallel 8
    popd
}

install_python_package() {
    echo "Installing python package"
    pushd python
    pip install -e .
    popd
}

# Install java
install_java_package() {
    echo "Installing java package"
    pushd jvm
    mvn install -pl core -DskipTests -Dcheckstyle.skip=true
    popd
}

cd $TVM_HOME
configure_cmake && \
build && \
install_python_package && \
if [ "$IS_JETSON" == "0" ]; then
    install_java_package
fi
