# MLC run scripts

This directory includes scripts for running MLC on different targets.
We support runtime through `expect` scripts, to interact with the `mlc_chat` executable for local and jetson execution.

Interaction with android/ios apps is happening over [phonelab](https://github.com/brave-experiments/blade-public).
Interaction with jetson is also coordinated with [jetsonlab](https://github.com/brave-experiments/jetsonlab-public).

## Structure

```bash
├── run-mlc-chat-cli.exp  # MLC expect script
├── run-mlc.sh            # Wrapper shell script
└── run_expect_all.sh     # Script for running all experiments
```

## How to run?

The `run-mlc.sh` script is the entry point for running experiments locally. Outside of this repo, this is used by `jetsonlab` for automated runtime of benchmarks. However, one can invoke the script manually if they desire.

```
./run-mlc.sh <model_path> <model_lib_path> <input_prompts_filename> <conversation_from> <conversation_to> <output_path> <events_filename> <iteration>

<model_path>: The path to the model
<model_lib_path>: The path to the library of the model (e.g. so file)
<input_prompts_filename>: The path of the input prompts json file
<conversation_from>: The ordinal of the conversation to start from
<conversation_to>: The ordinal of the conversation to end at
<output_path>: The output path for logs and metrics.
<events_filename>: The filename to use for energy events timestamps
<iteration>: The iteration (i.e. repetition) that this experiment is running.
```

## Known issues

* If you run the expect script on Mac OS, there is an issue where a message "your terminal doesn't support cursor position requests (CPR)" prevents the automation.