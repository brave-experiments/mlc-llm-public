#!/bin/bash
# Note:   This script is used to build mlc for iOS targets.
# Author: Stefanos Laskaridis (stefanos@brave.com)

export CARGO_PATH=${CARGO_PATH:-"$HOME/.cargo/bin"}
export PATH="$CARGO_PATH:$PATH"

export TVM_HOME=${TVM_HOME:-"$PWD/../../tvm-unity/"}
export MLC_HOME=${MLC_HOME:-"$PWD/../"}

build_aux_components() {
    pushd ios/
    rm -rf build/
    ./prepare_libs.sh
    popd
}

prepackage_model() {
    pushd ios/
    ./prepare_params.sh
    popd
}

cd $MLC_HOME
build_aux_components #&& \
# prepackage_model  # No longer needed as we are pushing models later to FS.
