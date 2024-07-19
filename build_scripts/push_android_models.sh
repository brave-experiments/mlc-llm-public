#! /bin/bash
# Note:   This script automatically transfers build models to iOS devices.
# Author: Stefanos Laskaridis (stefanos@brave.com)


MODEL_DIR=${MODEL_DIR:-"../../../../melt_models_converted/"}

if [ $# -gt 0 ]; then
    MODELS=("$@")
else
    MODELS=(
        "google_gemma-2b-it-q3f16_1"
        "google_gemma-2b-it-q4f16_1"
        "meta-llama_Llama-2-7b-chat-hf-q3f16_1"
        "meta-llama_Llama-2-7b-chat-hf-q4f16_1"
        "TinyLlama_TinyLlama-1.1B-Chat-v0.5-q3f16_1"
        "TinyLlama_TinyLlama-1.1B-Chat-v0.5-q4f16_1"
    )
fi

for model in "${MODELS[@]}";do
    echo Pushing model $model to /data/local/tmp
    adb push $MODEL_DIR/$model /data/local/tmp

    echo "Flatten directory on device"
    adb shell mv "/data/local/tmp/$model/params/* /data/local/tmp/$model/"

    echo "Moving model to app's directory"
    adb shell mv "/data/local/tmp/$model /storage/emulated/0/Android/data/ai.mlc.mlcchat/files/"
done