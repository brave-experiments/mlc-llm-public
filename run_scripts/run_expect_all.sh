#!/bin/bash

# Note:   This script is a wrapper for expect scripts that run mlc locally and on Jetson devices.
# Author: Stefanos Laskaridis (stefanos@brave.com)

MODEL_PATH=${MODEL_PATH:-"../../../../melt_models_converted"}
MODELS=(
    TinyLlama_TinyLlama-1.1B-Chat-v0.5
    stabilityai_stablelm-zephyr-3b
    mistralai_Mistral-7B-Instruct-v0.1
    meta-llama_Llama-2-7b-chat-hf
    meta-llama_Llama-2-13b-chat-hf
    google_gemma-2b-it
    google_gemma-7b-it
)
QUANTS=(
    q3f16_1
    q4f16_1
)
BACKEND=${BACKEND:-"metal"}
NUM_CONVS=${NUM_CONVS:-"1"}
LOG_DIR=${LOG_DIR:-"logs"}

for MODEL in ${MODELS[@]};do
    for QUANT in ${QUANTS[@]};do
        for RUN in $(seq 0 $(( REPETITIONS - 1 )));do
            ./run-mlc-chat-cli.exp ${MODEL_PATH}/${MODEL}-${QUANT}/params ${MODEL_PATH}/${MODEL}-${QUANT}/${MODEL}-${QUANT}-${BACKEND}.so  ../../../../src/prompts/conversations.json 0 $(( NUM_CONVS - 1 )) ${LOG_DIR}/${MODEL}-${QUANT}-${BACKEND} ${LOG_DIR}/${MODEL}-${QUANT}-${BACKEND}/melt_measurements/events.log $RUN
        done
    done
done