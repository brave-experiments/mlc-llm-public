package ai.mlc.mlcchat

import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL

class RestAwaitLib(private val host: String, private val port: Int) {

    fun continueExecution(): String {
        val url = URL("http://$host:$port/continue")
        val connection = url.openConnection() as HttpURLConnection
        connection.requestMethod = "GET"

        val responseCode = connection.responseCode
        if (responseCode == HttpURLConnection.HTTP_OK) {
            val reader = BufferedReader(InputStreamReader(connection.inputStream))
            val response = reader.readText()
            reader.close()
            return response
        } else {
            throw RuntimeException("GET request failed with response code: $responseCode")
        }
    }
}
