"""Python entrypoint of chat."""
import dataclasses
import re
import json
from typing import List, Optional, Union

from prompt_toolkit import prompt as get_prompt  # pylint: disable=import-error
from prompt_toolkit.key_binding import KeyBindings  # pylint: disable=import-error

from mlc_chat.callback import StreamToStdout
from mlc_chat.chat_module import ChatConfig, ChatModule, GenerationConfig
from mlc_chat.support import argparse
from mlc_chat.support.config import ConfigOverrideBase


@dataclasses.dataclass
class ChatConfigOverride(ConfigOverrideBase):  # pylint: disable=too-many-instance-attributes
    """Flags for overriding chat config."""

    conv_template: Optional[str] = None
    context_window_size: Optional[int] = None
    sliding_window_size: Optional[int] = None
    prefill_chunk_size: Optional[int] = None
    attention_sink_size: Optional[int] = None
    max_batch_size: Optional[int] = None
    tensor_parallel_shards: Optional[int] = None

    @staticmethod
    def from_str(source: str) -> "ChatConfigOverride":
        """Parse model config override values from a string."""
        parser = argparse.ArgumentParser(description="chat config override values")
        parser.add_argument("--conv_template", type=str, default=None)
        parser.add_argument("--tensor_parallel_shards", type=int, default=None)
        parser.add_argument("--context_window_size", type=int, default=None)
        parser.add_argument("--sliding_window_size", type=int, default=None)
        parser.add_argument("--prefill_chunk_size", type=int, default=None)
        parser.add_argument("--attention_sink_size", type=int, default=None)
        parser.add_argument("--max_batch_size", type=int, default=None)

        results = parser.parse_args([f"--{i}" for i in source.split(";") if i])
        return ChatConfigOverride(
            conv_template=results.conv_template,
            tensor_parallel_shards=results.tensor_parallel_shards,
            context_window_size=results.context_window_size,
            sliding_window_size=results.sliding_window_size,
            prefill_chunk_size=results.prefill_chunk_size,
            attention_sink_size=results.attention_sink_size,
            max_batch_size=results.max_batch_size,
        )


@dataclasses.dataclass
class GenerationConfigOverride(ConfigOverrideBase):  # pylint: disable=too-many-instance-attributes
    """Flags for overriding generation config."""

    temperature: Optional[float] = None
    repetition_penalty: Optional[float] = None
    top_p: Optional[float] = None
    mean_gen_len: Optional[int] = None
    max_gen_len: Optional[int] = None
    presence_penalty: Optional[float] = None
    frequency_penalty: Optional[float] = None
    n: Optional[int] = None  # pylint: disable=invalid-name
    stop: Optional[Union[str, List[str]]] = None

    @staticmethod
    def from_str(source: str) -> "GenerationConfigOverride":
        """Parse model config override values from a string."""
        parser = argparse.ArgumentParser(description="generation config override values")
        parser.add_argument("--temperature", type=float, default=None)
        parser.add_argument("--repetition_penalty", type=float, default=None)
        parser.add_argument("--top_p", type=float, default=None)
        parser.add_argument("--mean_gen_len", type=int, default=None)
        parser.add_argument("--max_gen_len", type=int, default=None)
        parser.add_argument("--presence_penalty", type=float, default=None)
        parser.add_argument("--frequency_penalty", type=float, default=None)
        parser.add_argument("--n", type=int, default=None)
        parser.add_argument("--stop", type=str, default=None)
        results = parser.parse_args([f"--{i}" for i in source.split(";") if i])
        return GenerationConfigOverride(
            temperature=results.temperature,
            repetition_penalty=results.repetition_penalty,
            top_p=results.top_p,
            mean_gen_len=results.mean_gen_len,
            max_gen_len=results.max_gen_len,
            presence_penalty=results.presence_penalty,
            frequency_penalty=results.frequency_penalty,
            n=results.n,
            stop=results.stop.split(",") if results.stop is not None else None,
        )


def _print_help_str():
    help_str = """You can use the following special commands:
  /help               print the special commands
  /exit               quit the cli
  /stats              print out the latest stats (token/sec)
  /reset              restart a fresh chat
  /set [overrides]    override settings in the generation config. For example,
                      `/set temperature=0.5;max_gen_len=100;stop=end,stop`
                      Note: Separate stop words in the `stop` option with commas (,).
  Multi-line input: Use escape+enter to start a new line.
"""
    print(help_str)


def _set_up_key_bindings():
    kb = KeyBindings()

    @kb.add("escape", "enter")
    def _(event):
        event.current_buffer.insert_text("\n")

    @kb.add("enter")
    def _(event):
        event.current_buffer.validate_and_handle()

    return kb


def chat(
    model: str,
    device: str,
    opt: str,
    overrides: ChatConfigOverride,
    model_lib_path: Optional[str],
    energy_events_filename: str,
):
    """chat with a model."""
    # Set up chat config and generate config
    config = ChatConfig(opt=opt)
    generate_config = GenerationConfig()
    # Apply overrides
    config = overrides.apply(config)
    # Set up ChatModule
    cm = ChatModule(model, device, chat_config=config, model_lib_path=model_lib_path)
    _print_help_str()
    cm._process_system_prompts()  # pylint: disable=protected-access

    # Multi-line input support: set escape+enter as start a new line
    kb = _set_up_key_bindings()

    while True:
        prompt = get_prompt(
            f"{cm._get_role_0()}: ",  # pylint: disable=protected-access
            key_bindings=kb,
            multiline=True,
        )
        if prompt[:6] == "/reset":
            cm.reset_chat()
        elif prompt[:5] == "/exit":
            with open(energy_events_filename, 'w', encoding='utf-8') as f:
                for event_key, event_value in cm.energy_events.items():
                    f.write(f"{event_key} {event_value}\n")
            break
        elif prompt[:6] == "/stats":
            # print(cm.stats(verbose=True), flush=True)
            # ----------- prefill -----------
            # throughput: 87.899 tok/s
            # total tokens: 10 tok
            # total time: 0.114 s
            # ------------ decode ------------
            # throughput: 54.603 tok/s
            # total tokens: 18 tok
            # total time: 0.330 s
            # Parse the above metrics into json format
            stats = cm.stats(verbose=True)
            if stats.startswith("{"):  # This is already handled by the backend
                print(stats, flush=True)
            else:  # This is in case the backend has not been changed
                stats = stats.strip().split("\n")
                float_re = re.compile(r"\d+\.\d+")
                int_re = re.compile(r"\d+")
                stats_dict = {}
                try:
                    for i in range(0, len(stats), 4):
                        stats_dict[stats[i].strip('-').strip()] = {
                            "throughput": f"{float(re.findall(float_re, stats[i + 1])[0])} tok/s",
                            "total_tokens": f"{int(re.findall(int_re, stats[i + 2])[0])} tok",
                            "total_time": f"{float(re.findall(float_re, stats[i + 3])[0])} s",
                        }
                    print(json.dumps(stats_dict, indent=4), flush=True)
                except IndexError:
                    print(stats, flush=True)
        elif prompt[:4] == "/set":
            gen_config_overrides = GenerationConfigOverride.from_str(prompt.split()[1])
            generate_config = gen_config_overrides.apply(generate_config)
        elif prompt[:5] == "/help":
            _print_help_str()
        else:
            print(f"{cm._get_role_1()}: ")  # pylint: disable=protected-access
            cm.generate(
                prompt,
                progress_callback=StreamToStdout(callback_interval=2),
                generation_config=generate_config,
            )
