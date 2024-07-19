package ai.mlc.mlcllm;

import org.apache.tvm.Device;
import org.apache.tvm.Function;
import org.apache.tvm.Module;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.*;

public class ChatModule {
    private Function reloadFunc;
    private Function unloadFunc;
    private Function prefillFunc;
    private Function decodeFunc;
    private Function getMessage;
    private Function stoppedFunc;
    private Function resetChatFunc;
    private Function runtimeStatsTextFunc;
    private Function verboseRuntimeStatsTextFunc;
    private Module llmChat;

    private HashMap<String, String> energyEvents = new HashMap<>();
    private int unload_counter = 0;
    private int reload_counter = 0;
    private int reset_chat_counter = 0;
    private int decode_counter = 0;
    private int prefill_counter = 0;
    private int get_message_counter = 0;
    private int stopped_counter = 0;


    public ChatModule() {
        energyEvents.put("init.start", String.valueOf(System.currentTimeMillis() * 1000000));
        Function createFunc = Function.getFunction("mlc.llm_chat_create");
        assert createFunc != null;
        llmChat = createFunc.pushArg(Device.opencl().deviceType).pushArg(0).invoke().asModule();
        reloadFunc = llmChat.getFunction("reload");
        unloadFunc = llmChat.getFunction("unload");
        prefillFunc = llmChat.getFunction("prefill");
        decodeFunc = llmChat.getFunction("decode");
        getMessage = llmChat.getFunction("get_message");
        stoppedFunc = llmChat.getFunction("stopped");
        resetChatFunc = llmChat.getFunction("reset_chat");
        runtimeStatsTextFunc = llmChat.getFunction("runtime_stats_text");
        verboseRuntimeStatsTextFunc = llmChat.getFunction("verbose_runtime_stats_text");
        energyEvents.put("init.end", String.valueOf(System.currentTimeMillis() * 1000000));
    }

    public void unload() {
        energyEvents.put("unload." + unload_counter + ".start", String.valueOf(System.currentTimeMillis() * 1000000));
        unloadFunc.invoke();
        energyEvents.put("unload." + unload_counter + ".end", String.valueOf(System.currentTimeMillis() * 1000000));
        unload_counter++;
    }

    public void reload(
        String modelLib,
        String modelPath
    ) {
        String libPrefix = modelLib.replace('-', '_') + "_";
        Function systemLibFunc = Function.getFunction("runtime.SystemLib");
        assert systemLibFunc != null;
        systemLibFunc = systemLibFunc.pushArg(libPrefix);
        Module lib = systemLibFunc.invoke().asModule();
        reloadFunc = reloadFunc.pushArg(lib).pushArg(modelPath);
        energyEvents.put("reload." + reload_counter + ".start", String.valueOf(System.currentTimeMillis() * 1000000));
        reloadFunc.invoke();
        energyEvents.put("reload." + reload_counter + ".end", String.valueOf(System.currentTimeMillis() * 1000000));
        reload_counter++;
    }

    public void resetChat() {
        energyEvents.put("reset_chat." + reset_chat_counter + ".start", String.valueOf(System.currentTimeMillis() * 1000000));
        resetChatFunc.invoke();
        energyEvents.put("reset_chat." + reset_chat_counter + ".end", String.valueOf(System.currentTimeMillis() * 1000000));
        reset_chat_counter++;
    }

    public void prefill(String input) {
        energyEvents.put("prefill." + prefill_counter + ".start", String.valueOf(System.currentTimeMillis() * 1000000));
        prefillFunc.pushArg(input).invoke();
        energyEvents.put("prefill." + prefill_counter + ".end", String.valueOf(System.currentTimeMillis() * 1000000));
        prefill_counter++;
    }

    public String getMessage() {
        energyEvents.put("get_message." + get_message_counter + ".start", String.valueOf(System.currentTimeMillis() * 1000000));
        String message = getMessage.invoke().asString();
        energyEvents.put("get_message." + get_message_counter + ".end", String.valueOf(System.currentTimeMillis() * 1000000));
        get_message_counter++;
        return message;
    }

    public String runtimeStatsText() {
        energyEvents.put("runtime_stats_text.start", String.valueOf(System.currentTimeMillis() * 1000000));
        String runtimeStatsText = runtimeStatsTextFunc.invoke().asString();
        energyEvents.put("runtime_stats_text.end", String.valueOf(System.currentTimeMillis() * 1000000));
        return runtimeStatsText;
    }

    public String verboseRuntimeStatsText() {
        energyEvents.put("verbose_runtime_stats_text.start", String.valueOf(System.currentTimeMillis() * 1000000));
        String runtimeStatsText = verboseRuntimeStatsTextFunc.invoke().asString();
        energyEvents.put("verbose_runtime_stats_text.end", String.valueOf(System.currentTimeMillis() * 1000000));
        return runtimeStatsText;
    }

    public void evaluate() {
        energyEvents.put("evaluate.start", String.valueOf(System.currentTimeMillis() * 1000000));
        llmChat.getFunction("evaluate").invoke();
        energyEvents.put("evaluate.end", String.valueOf(System.currentTimeMillis() * 1000000));
    }

    public boolean stopped() {
        energyEvents.put("stopped." + stopped_counter + ".start", String.valueOf(System.currentTimeMillis() * 1000000));
        boolean stopped = stoppedFunc.invoke().asLong() != 0L;
        energyEvents.put("stopped." + stopped_counter + ".end", String.valueOf(System.currentTimeMillis() * 1000000));
        stopped_counter++;
        return stopped;
    }

    public void decode() {
        energyEvents.put("generate.decode." + decode_counter + ".start", String.valueOf(System.currentTimeMillis() * 1000000));
        decodeFunc.invoke();
        energyEvents.put("generate.decode." + decode_counter + ".end", String.valueOf(System.currentTimeMillis() * 1000000));
        decode_counter++;
    }

    public void resetEnergyEvents() {
        energyEvents.clear();
        unload_counter = 0;
        reload_counter = 0;
        reset_chat_counter = 0;
        decode_counter = 0;
        prefill_counter = 0;
        get_message_counter = 0;
        stopped_counter = 0;
    }

    public void saveEnergyEventsToCSV(File file) {

        try (FileWriter writer = new FileWriter(file)) {

            for (Map.Entry<String, String> entry : energyEvents.entrySet()) {
                writer.append(entry.getKey())
                      .append(",")
                      .append(entry.getValue())
                      .append("\n");
            }

        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}