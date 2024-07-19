# Building android

Following the guide from [here](https://mlc.ai/mlc-llm/docs/deploy/android.html).

1. We start by cloning the mlc-llm project

```
git clone --recursive git@github.com:brave-experiments/mlc-llm.git
```

and TVM-unity

```
git clone --recursive git@github.com:mlc-ai/relax.git tvm-unity
```

2. We install Android Studio and point the following variables to the internally downloaded android sdks

```
export TVM_NDK_CC="$HOME/Library/Android/sdk/ndk/25.2.9519653/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android24-clang"
export ANDROID_NDK="$HOME/Library/Android/sdk/ndk/25.2.9519653/"
```

3. We install mvn through homebrew, which also installs java. Since these are casks, we need to export the proper env vars for this to work. We launch Android studio from that terminal we have the envvars exported.

```
brew install maven
brew info openjdk # to check what needs to be exported
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
```

4. We build TVM from source with OpenCL enabled. The folder needs to be symlinked to tvm-home in the mlc-llm repo.

5. We build TVM4j

```
cd tvm-unity
cd jvm; mvn install -pl core -DskipTests -Dcheckstyle.skip=true
```

6. We compile the model via mlc

```
export PATH="$HOME/.cargo/bin:$PATH"
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export TVM_HOME="$HOME/Documents/brave-projects/LLMs/tvm-unity/"
export PATH="$HOME/.cargo/bin:$PATH"

python3 build.py --model path/to/vicuna-v1-7b --quantization q4f16_0 --target android --max-seq-len 768
```

7. In the Android Studio, we open the project and change the `assets/app-config.json` file to include the compiled model of ours. We don't need to put a url that works.

8. We push the models to the device, under the following path: `/storage/emulated/0/Android/data/ai.mlc.mlcchat/files/`. Pushing straight to that directory does not work, so we have to first push to `/data/local/tmp/` and then move from that directory internally through `adb shell`. In the android directory, the params are expected to be flat in the directory, not under the params/ folder.

9. To build the application with custom models, we need to sign it ourselves (through build > Generate signed bundle/apk) and install it through `adb install`.