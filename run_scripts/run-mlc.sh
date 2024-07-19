#!/bin/bash

# Note:   This script is used to run the MLC models locally.
# Author: Stefanos Laskaridis (stefanos@brave.com)

# show script usage
if [ $# -ne 8 ]
then
	echo "===================================================="
	echo "USAGE: $0 model_path model_lib_path input_prompts_filename conversation_from conversation_to output_path events_filename iteration"
    echo "Passed parameters: $@"
	echo "===================================================="
	exit -1
fi
MODEL_PATH=$1
MODEL_LIB_PATH=$2
INPUT_PROMPTS_FILENAME=$3
CONVERSATION_FROM=$4
CONVERSATION_TO=$5
OUTPUT_PATH=$6
EVENTS_FILENAME=$7
ITERATION=$8

FILE_DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
REAL_OUTPUT_PATH=$(realpath $OUTPUT_PATH)

# Check device type and set expect_script accordingly
expect_script="run-mlc-chat-cli.exp"

# iterate per conversation
for (( i=CONVERSATION_FROM; i<CONVERSATION_TO; i++ ))
do
    mkdir -p $REAL_OUTPUT_PATH/melt_measurements
    pushd $FILE_DIRECTORY
    # Execute the appropriate $expect_script for particular conversation
    echo "Running: ./$expect_script \"$MODEL_PATH\" \"$MODEL_LIB_PATH\" \"$INPUT_PROMPTS_FILENAME\" $i $i \"$REAL_OUTPUT_PATH\" \"${EVENTS_FILENAME}_iter${ITERATION}_conv$i.tsv\" ${ITERATION}"
    ./$expect_script "$MODEL_PATH" "$MODEL_LIB_PATH" "$INPUT_PROMPTS_FILENAME" $i $i "$REAL_OUTPUT_PATH" "${EVENTS_FILENAME}_iter${ITERATION}_conv$i.tsv" ${ITERATION}
    sleep 1
    popd
done
