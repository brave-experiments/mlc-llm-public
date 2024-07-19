package ai.mlc.mlcchat

import android.os.Environment
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.IOException
import java.util.*

data class ConversationRecord(
    val modelName: String,
    val modelLoadTime: TimeRecord,
    val questionRecords: MutableList<QuestionRecord> = mutableListOf()
)

data class QuestionRecord(
    val time: TimeRecord,
    val input: String,
    val output: String,
    val original_session_tokens: Int,
    val input_tokens: Int,
    val output_tokens: Int,
    val runtimeStats: String
)

data class TimeRecord(
    val start: Date,
    val duration: Long
)

class ConversationsRecordManager {
    private val conversations: ArrayList<ConversationRecord> = ArrayList()

    fun addConversationRecord(conversation: ConversationRecord) {
        conversations.add(conversation)
    }

    fun saveToFile(fileName: String) {
        val file = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS).toString() + File.separator + "melt_measurements",
            "$fileName.json"
        )

        if (!file.parentFile.exists()) {
            file.parentFile.mkdirs()
        }

        try {
            val jsonArray = JSONArray()
            for (session in conversations) {
                val sessionObject = JSONObject()
                sessionObject.put("modelName", session.modelName)

                val modelLoadTime = JSONObject()
                val startEpoch = session.modelLoadTime.start.time / 1000.0
                modelLoadTime.put("start", startEpoch)
                modelLoadTime.put("duration", session.modelLoadTime.duration / 1000.0)
                sessionObject.put("modelLoadTime", modelLoadTime)

                val questionRecordsArray = JSONArray()
                for (questionRecord in session.questionRecords) {
                    val chatRecordObject = JSONObject()
                    val timeRecordObject = JSONObject()

                    val questionStartEpoch = questionRecord.time.start.time / 1000.0
                    timeRecordObject.put("start", questionStartEpoch)
                    timeRecordObject.put("duration", questionRecord.time.duration / 1000.0)

                    chatRecordObject.put("time", timeRecordObject)
                    chatRecordObject.put("input", questionRecord.input)
                    chatRecordObject.put("output", questionRecord.output)
                    chatRecordObject.put("original_session_tokens", questionRecord.original_session_tokens)
                    chatRecordObject.put("input_tokens", questionRecord.input_tokens)
                    chatRecordObject.put("output_tokens", questionRecord.output_tokens)
                    chatRecordObject.put("runtimeStats", questionRecord.runtimeStats)

                    questionRecordsArray.put(chatRecordObject)
                }
                sessionObject.put("questionRecords", questionRecordsArray)

                jsonArray.put(sessionObject)
            }
            file.writeText(jsonArray.toString(4))
            Log.d("SessionRecordManager", "JSON data successfully saved at: " + file.absolutePath)
        } catch (e: IOException) {
            Log.e("SessionRecordManager", "Failed to write JSON data: ${e.localizedMessage}")
        }
    }
}
