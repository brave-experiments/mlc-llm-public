#! /bin/bash
# Note:   This script automatically transfers build models to iOS devices.
# Author: Stefanos Laskaridis (stefanos@brave.com)


MODEL_DIR=${MODEL_DIR:-"../../../../melt_models_converted/"}
if [ $# -gt 0 ]; then
    MODELS=("$@")
else
    MODELS=(
        "meta-llama_Llama-2-7b-chat-hf-q3f16_1"
        "meta-llama_Llama-2-7b-chat-hf-q4f16_1"
        "mistralai_Mistral-7B-Instruct-v0.1-q3f16_1"
        "mistralai_Mistral-7B-Instruct-v0.1-q4f16_1"
        "mistralai_Mistral-7B-Instruct-v0.1-q0f32"
        "TinyLlama_TinyLlama-1.1B-Chat-v0.5-q3f16_1"
        "TinyLlama_TinyLlama-1.1B-Chat-v0.5-q4f16_1"
        "TinyLlama_TinyLlama-1.1B-Chat-v0.5-q0f32"
        "stabilityai_stablelm-zephyr-3b-q3f16_1"
        "stabilityai_stablelm-zephyr-3b-q4f16_1"
    )
fi
MLC_MOUNTPOINT=${MLC_MOUNTPOINT:-"/tmp/iphone_mlc_mount"}

# Make sure that mountpoints exist
mkdir -p ${MLC_MOUNTPOINT}

echo Mounting MLC folder
ifuse --documents 'com.brave.mlc.Chat32' ${MLC_MOUNTPOINT}

for model in "${MODELS[@]}";do
    echo Pushing model $model to MLC folder
    cp -rv ${MODEL_DIR}/${model} ${MLC_MOUNTPOINT}/
    mv -rv ${MLC_MOUNTPOINT}/${model}/params/* ${MLC_MOUNTPOINT}/${model}/
done

echo Unmounting MLC folder
fusermount -u ${MLC_MOUNTPOINT}
