# MLC build scripts

This directory includes scripts for building [tvm](https://github.com/mlc-ai/relax.git) and [mlc-llm](https://github.com/mlc-ai/mlc-llm) against different targets.

## Structure

```bash
├── build_android.sh            # Build script for building android requirements (not app)
├── build_ios.sh                # Build script for building ios requirements (not app)
├── build_mlc.sh                # Build script for building mlc locally
├── build_tvm_unity.sh          # Build script for building tvm locally
├── install_android_apk.sh      # Script for installing Android apk to device
├── install_ios_ipa.sh          # Script for installing iOS ipa to device
├── push_android_models.sh      # Push android models to device
├── push_ios_models.sh          # Push ios models to device
└── run_jetson_docker.sh        # Script for launching dusty-nv's container (used to build tvm and mlc on jetsons)
```

## How to run

## Build locally

To build MLC and TVM locally, we largely used the instructions from [here](https://llm.mlc.ai/docs/install/mlc_llm#option-2-build-from-source), albeit a previous version. Please follow the steps below to build:

1. Create python environment

```bash
conda create -n mlc-chat-venv -c conda-forge \
    cmake \
    rust \
    git \
    llvmdev \
    "python=3.11"

# enter the build environment
conda activate mlc-chat-venv
```

2. Build TVM Unity

```bash
# Make sure that your PATHS are correct in the script, or override them through ENV VARS.
./build_tvm_unity.sh

# Verify that tvm is installed
python -c "import tvm; print(tvm.runtime)"
```

3. Build MLC Unity

```bash
./build_mlc.sh
```

4. Make sure your models are built in the expected directories

For this, you need to follow instructions from `src/models/README.md` in the MELT directory. Obviously, you need to have installed MLC before compiling and quantizing models to MLC format.

5. Build for mobile (iOS, Android)

After you've built TVM and MLC, you need to do the following:

**Instructions for android:**

* Edit the models you want to run in your application by populating the file `android/app/src/main/assets/app-config.json`.
* Check that your built model path is populated correctly in `android/library/prepare_model_lib.py`.
* Build android libraries, by running: `./build_android.sh`.
    * You need to either install the same JAVA version we have used, or point the JAVA_HOME env variable to the proper path.
    * The same applies for the proper NDK version; please point TVM_NDK_CC and ANDROID_NDK to the proper paths.
* Open mlc/android in Android Studio, with JAVA_HOME and ANDROID_NDK pointing to the correct paths.
* Configure gradle and dependencies.
* Build signed apk (`Build > Generate Signed Bundle / APK > APK`), generate your keys and build apk.
* Install your APK to your connected phone by running `./install_android_apk.sh`.
* Populate models to your device by running `./push_android_models.sh`. You can give the models as an argument.


**Instructions for iOS:**

* Edit the models you want to run in your application by populating the file `ios/MLCChat/app-config.json` and the `builtin_list` at `frameworks/MLC/mlc-llm/ios/prepare_params.sh`.
* Check that your build model path is populated correctly in `frameworks/MLC/mlc-llm/ios/prepare_model_lib.py`.
* Build ios libraries, by running: `./build_ios.sh`
* Open mlc/ios in XCode and build
* Export ipa signed application archive (`Product > Archive > Distribute App > Release Testing > Export`).
* Install your .ipa generated file to your connected phone by running `./install_ios_ipa.sh`.
* Populate models to your device by running `./push_ios_models.sh`. You can give the models as an argument.

**WARNING**: By default, the models are copied with iFuse, which can be painfully slow. Alternatively, you can copy models on device to the application directory through Finder, which we found to be significantly faster.

**Caveats**: If you try running llama-2-q3f16 (or another similarly sized model) in iPhones, with the default settings, you'll be running out of memory. Try using smaller context-size to remain within memory limits.


**Instructions for Jetsons:**

* Launch [dusty-nv's](https://github.com/dusty-nv/jetson-containers) container by running `./run_jetson_docker.sh`.
* Build mlc from inside the container, by following the same instructions as in steps 1-3.