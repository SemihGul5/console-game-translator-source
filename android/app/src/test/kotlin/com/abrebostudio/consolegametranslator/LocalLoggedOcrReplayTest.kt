package com.abrebostudio.consolegametranslator

import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import java.util.concurrent.Executor

/** User gameplay OCR, with a simulated 600 ms local model so reads arrive during inference. */
class LocalLoggedOcrReplayTest {
    @Test fun reportedDialogueContinuesAfterTheRoomLineWithoutAnInferenceBacklog() {
        val sessions = JSONObject(javaClass.getResource("/local-ocr-2026-11-16.json")!!.readText()).getJSONArray("sessions")
        for (sessionIndex in 0 until sessions.length()) {
            val session = sessions.getJSONObject(sessionIndex)
            val rows = session.getJSONArray("rows")
            var time = 0L
            var index = 0
            var current: String? = null
            var translating: String? = null
            var visible = false
            var lastNonempty = 0L
            var calls = 0
            val cache = mutableMapOf<String, String>()
            val delivered = mutableListOf<Pair<Long, String>>()
            val tasks = ArrayDeque<Runnable>()
            val queue = LatestLocalTranslationQueue(Executor { tasks.add(it) })
            val policy = DeepLOcrPolicy { time }

            fun millis(value: String): Long {
                val parts = value.split(':', '.')
                return ((parts[0].toLong() * 60 + parts[1].toLong()) * 60 + parts[2].toLong()) * 1000 + parts[3].toLong()
            }
            lateinit var read: (JSONObject) -> Unit
            read = { row ->
                val text = row.getString("text")
                val confidence = row.getDouble("confidence").toFloat()
                if (text.isBlank() || confidence < .35f) {
                    policy.discardPending()
                    if (time - lastNonempty > 2000) { policy.clear(); current = null; translating = null; visible = false }
                } else {
                    lastNonempty = time
                    val confirmed = policy.observe(text, confidence, "en", 67)
                    if (confirmed != null) {
                        if (current != confirmed.key) { current = confirmed.key; visible = false }
                        if (!visible) {
                            val cached = cache[confirmed.key]
                            if (cached != null) { visible = true; delivered.add(time to cached) }
                            else if (translating != confirmed.key) {
                                translating = confirmed.key
                                queue.submit(0, confirmed.key) {
                                    calls++
                                    val finish = time + 600
                                    while (index < rows.length() && millis(rows.getJSONObject(index).getString("time")) <= finish) {
                                        val next = rows.getJSONObject(index++)
                                        time = millis(next.getString("time"))
                                        read(next)
                                    }
                                    time = finish
                                    cache[confirmed.key] = confirmed.text
                                    if (translating == confirmed.key) translating = null
                                    if (current == confirmed.key && policy.requestKey == confirmed.key) {
                                        visible = true; delivered.add(time to confirmed.text)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            while (index < rows.length() || tasks.isNotEmpty()) {
                if (tasks.isNotEmpty()) tasks.removeFirst().run()
                else {
                    val row = rows.getJSONObject(index++)
                    time = millis(row.getString("time"))
                    read(row)
                }
            }
            for (fragment in listOf("his room all day", "other people to go with", "marina", "clear my head")) {
                assertTrue("${session.getString("name")}: missing $fragment", delivered.any { it.second.contains(fragment, ignoreCase = true) })
            }
            val firstNextLine = (0 until rows.length()).map { rows.getJSONObject(it) }
                .first { it.getString("text").contains("other people to go with", ignoreCase = true) }
            val nextDelivery = delivered.first { it.second.contains("other people to go with", ignoreCase = true) }
            val delay = nextDelivery.first - millis(firstNextLine.getString("time"))
            println("LOCAL_REPLAY session=${session.getString("name")} reads=${rows.length()} inferences=$calls nextLineDelayMs=$delay")
            assertTrue("New dialogue must not disappear while OCR variants churn", delay in 0..2500)
            assertTrue("Work must be bounded by real dialogue, not every OCR frame", calls < rows.length() / 5)
        }
    }
}
