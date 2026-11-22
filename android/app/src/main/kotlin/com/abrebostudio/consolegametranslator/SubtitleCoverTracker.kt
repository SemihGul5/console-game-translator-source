package com.abrebostudio.consolegametranslator

import java.util.Locale
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

/** A rectangle in the whole video frame, 0..1 on each axis from the top-left. */
internal data class CoverBox(val left: Float, val top: Float, val right: Float, val bottom: Float) {
    val width get() = right - left
    val height get() = bottom - top
    val centerX get() = (left + right) / 2f
    val centerY get() = (top + bottom) / 2f

    fun union(other: CoverBox) = CoverBox(min(left, other.left), min(top, other.top), max(right, other.right), max(bottom, other.bottom))

    fun overlapsHorizontally(other: CoverBox) = min(right, other.right) > max(left, other.left)
}

/** One recognized OCR line, already mapped into the frame. */
internal data class CoverLine(val text: String, val box: CoverBox)

/**
 * One subtitle as it stands on screen: a speaker's line, or the lines that
 * continue it. [prompt] marks one label of a controller prompt row
 * ([splitCoverPrompts]): it is translated on its own and its cover keeps to the
 * label's size, so the game's buttons beside it stay visible.
 */
internal data class CoverUnit(val text: String, val box: CoverBox, val lineHeight: Float, val prompt: Boolean = false)

/**
 * Splits the subtitle area's lines into separate subtitles, so speakers talking
 * one after another ("Cal: …" above "Jason: …") are matched and covered one by
 * one. A line starts a new subtitle when it begins with a speaker label, when it
 * is clearly separated from the subtitle above it, or when it does not overlap
 * it horizontally (another column of text). The lines below a speaker's line
 * continue it (a two-line subtitle).
 */
internal fun groupCoverUnits(lines: List<CoverLine>): List<CoverUnit> {
    val rows = lines.filter { it.text.isNotBlank() && it.box.height > 0f }
        .sortedWith(compareBy<CoverLine> { it.box.top }.thenBy { it.box.left })
    if (rows.isEmpty()) return emptyList()
    val typicalHeight = rows.map { it.box.height }.sorted()[rows.size / 2]
    val groups = ArrayList<MutableList<CoverLine>>()
    for (line in rows) {
        val current = groups.lastOrNull()
        val previousBox = current?.map { it.box }?.reduce(CoverBox::union)
        val startsNew = current == null || previousBox == null ||
            COVER_SPEAKER_LABEL.containsMatchIn(line.text) ||
            line.box.top - previousBox.bottom > typicalHeight * NEW_SUBTITLE_GAP_LINES ||
            (!line.box.overlapsHorizontally(previousBox) && !sameRowNeighbour(current!!.last().box, line.box, typicalHeight))
        if (startsNew) groups.add(mutableListOf(line)) else current!!.add(line)
    }
    return groups.map { group ->
        CoverUnit(
            text = readingOrder(group).joinToString(" ") { it.text.trim() },
            box = group.map { it.box }.reduce(CoverBox::union),
            lineHeight = group.map { it.box.height }.sorted()[group.size / 2],
        )
    }
}

/**
 * The translation chosen for one subtitle. [key] identifies the source line (the
 * same pack entry keeps the same key however OCR spells it); [immediate] lets a
 * certain match appear without waiting for a second frame.
 */
internal data class CoverMatch(
    val key: String,
    val text: String,
    val immediate: Boolean,
    /** Button icons (PNG, base64) drawn where [text] holds [ICON_PLACEHOLDER]. */
    val icons: List<String> = emptyList(),
)

internal data class CoverObservation(val unit: CoverUnit, val match: CoverMatch?)

/** What is drawn over the English: [box] is the English subtitle's place in the frame. */
internal data class CoverItem(
    val id: Int,
    val text: String,
    val box: CoverBox,
    val lineHeight: Float,
    val icons: List<String> = emptyList(),
    /** A prompt label: drawn at the English label's size, never wider than needed. */
    val fit: Boolean = false,
)

/**
 * Turns frame-by-frame subtitle reads into a calm list of covers.
 *
 * - A different translation at the same place replaces the shown one only after
 *   [confirmFrames] consecutive frames, so reads alternating between two
 *   spellings ("I just" / "T just") never flicker.
 * - A new subtitle appears at once when its match is certain, otherwise after
 *   [confirmFrames] consecutive frames.
 * - The box follows the English only when it really moves (more than half a
 *   line, or a clearly different size); OCR jitter does not shake it.
 * - Missed reads do not remove a cover; it goes when its subtitle has not been
 *   seen for [missMillis].
 * - When no subtitle in the area is in the game pack, the area's live
 *   translation ([setLiveText]) covers all of its English as one box.
 */
internal class SubtitleCoverTracker(
    private val missMillis: Long = DEFAULT_MISS_MILLIS,
    private val confirmFrames: Int = DEFAULT_CONFIRM_FRAMES,
) {
    private class Shown(
        val id: Int,
        var key: String,
        var text: String,
        var box: CoverBox,
        var lineHeight: Float,
        var lastSeen: Long,
        var icons: List<String> = emptyList(),
        var fit: Boolean = false,
        var pendingKey: String? = null,
        var pendingCount: Int = 0,
    )

    private class Candidate(
        val key: String,
        val text: String,
        val box: CoverBox,
        val lineHeight: Float,
        val immediate: Boolean,
        val icons: List<String> = emptyList(),
        val fit: Boolean = false,
    )

    private class Pending(var count: Int, var lastFrame: Long)

    private val shown = ArrayList<Shown>()
    private val pendingNew = HashMap<String, Pending>()
    private var liveText: String? = null
    private var liveSource: String? = null
    private var liveIcons: List<String> = emptyList()
    private var nextId = 1
    private var frame = 0L
    private var published: List<CoverItem> = emptyList()

    /**
     * The area's current live translation (not from the game pack), or null.
     * [source] is the English it was made from: the translation is only drawn
     * over subtitles that read like it, never over other text that is still on
     * screen (a brand on a bottle) after its own subtitle has gone.
     */
    @Synchronized fun setLiveText(text: String?, source: String? = null, icons: List<String> = emptyList()) {
        liveText = text?.takeIf { it.isNotBlank() }
        liveSource = if (liveText == null) null else source?.takeIf { it.isNotBlank() }
        liveIcons = if (liveText == null) emptyList() else icons
    }

    /** True while the area's live translation is set ([setLiveText]). */
    @Synchronized fun hasLiveText(): Boolean = liveText != null

    /** Forget everything (area turned off, stream stopped). Returns the empty list if covers were shown. */
    @Synchronized fun reset(): List<CoverItem>? {
        shown.clear()
        pendingNew.clear()
        liveText = null
        liveSource = null
        liveIcons = emptyList()
        frame = 0
        return publish(emptyList())
    }

    /** Feed one frame. Returns the new cover list when what should be on screen changed, otherwise null. */
    @Synchronized fun observe(observations: List<CoverObservation>, now: Long): List<CoverItem>? {
        frame++
        val candidates = candidatesFrom(observations)
        val unassigned = candidates.toMutableList()
        val claimed = HashSet<Shown>()
        // The same source line first, wherever OCR now places it; then by place.
        for (item in shown) {
            val sameKey = unassigned.firstOrNull { it.key == item.key } ?: continue
            unassigned.remove(sameKey)
            claimed.add(item)
            keep(item, sameKey, now)
        }
        for (item in shown) {
            if (item in claimed) continue
            val atPlace = unassigned.filter { samePlace(item, it) }.minByOrNull { abs(it.box.centerY - item.box.centerY) } ?: continue
            unassigned.remove(atPlace)
            claimed.add(item)
            replaceWhenConfirmed(item, atPlace, now)
        }
        for (candidate in unassigned) {
            val pending = pendingNew.getOrPut(candidate.key) { Pending(0, frame - 1) }
            pending.count = if (pending.lastFrame == frame - 1) pending.count + 1 else 1
            pending.lastFrame = frame
            if (candidate.immediate || pending.count >= confirmFrames) {
                pendingNew.remove(candidate.key)
                shown.add(Shown(nextId++, candidate.key, candidate.text, candidate.box, candidate.lineHeight, now,
                    candidate.icons, candidate.fit))
            }
        }
        pendingNew.entries.removeAll { it.value.lastFrame < frame }
        shown.removeAll { now - it.lastSeen > missMillis }
        return publish(shown.sortedWith(compareBy<Shown> { it.box.top }.thenBy { it.box.left })
            .map { CoverItem(it.id, it.text, it.box, it.lineHeight, it.icons, it.fit) })
    }

    private fun candidatesFrom(observations: List<CoverObservation>): List<Candidate> {
        val matched = observations.filter { it.match != null }
        if (matched.isNotEmpty()) return matched.map { (unit, match) ->
            Candidate(match!!.key, match.text, unit.box, unit.lineHeight, match.immediate, match.icons, unit.prompt)
        }
        val live = liveText ?: return emptyList()
        val source = liveSource
        // Prompt labels wait for their own translations; the whole area's live
        // text is never stretched over them.
        val lines = observations.filterNot { it.unit.prompt }
        val units = if (source == null) lines else lines.filter { readsLike(it.unit.text, source) }
        if (units.isEmpty()) return emptyList()
        val box = units.map { it.unit.box }.reduce(CoverBox::union)
        val lineHeight = units.map { it.unit.lineHeight }.sorted()[units.size / 2]
        // The live pipeline has already corroborated this text before showing it.
        return listOf(Candidate("$LIVE_KEY_PREFIX$live", live, box, lineHeight, immediate = true, icons = liveIcons))
    }

    private fun keep(item: Shown, candidate: Candidate, now: Long) {
        item.lastSeen = now
        item.pendingKey = null
        item.pendingCount = 0
        // A button icon found a frame later is added once; a frame that misses
        // the icon never takes it away again.
        if (item.icons.isEmpty() && candidate.icons.isNotEmpty()) {
            item.text = candidate.text
            item.icons = candidate.icons
        }
        if (moved(item.box, candidate.box, max(item.lineHeight, candidate.lineHeight))) {
            item.box = candidate.box
            item.lineHeight = candidate.lineHeight
        }
    }

    private fun replaceWhenConfirmed(item: Shown, candidate: Candidate, now: Long) {
        val live = candidate.key.startsWith(LIVE_KEY_PREFIX) && item.key.startsWith(LIVE_KEY_PREFIX)
        if (item.pendingKey == candidate.key) item.pendingCount++ else {
            item.pendingKey = candidate.key
            item.pendingCount = 1
        }
        if (!live && item.pendingCount < confirmFrames) return
        item.key = candidate.key
        item.text = candidate.text
        item.icons = candidate.icons
        item.fit = candidate.fit
        item.box = candidate.box
        item.lineHeight = candidate.lineHeight
        item.lastSeen = now
        item.pendingKey = null
        item.pendingCount = 0
    }

    private fun samePlace(item: Shown, candidate: Candidate): Boolean {
        val lineHeight = max(item.lineHeight, candidate.lineHeight)
        return item.box.overlapsHorizontally(candidate.box) &&
            min(item.box.bottom, candidate.box.bottom) - max(item.box.top, candidate.box.top) > -lineHeight * SAME_PLACE_LINES
    }

    private fun moved(old: CoverBox, new: CoverBox, lineHeight: Float): Boolean =
        abs(new.centerY - old.centerY) > lineHeight * MOVE_LINES ||
            abs(new.centerX - old.centerX) > lineHeight * MOVE_LINES * 2 ||
            abs(new.width - old.width) > old.width * RESIZE_RATIO ||
            abs(new.height - old.height) > old.height * RESIZE_RATIO

    /** At least half of the subtitle's words appear in the English the live translation came from. */
    private fun readsLike(unitText: String, source: String): Boolean {
        val words = coverWords(unitText)
        if (words.isEmpty()) return false
        val sourceWords = coverWords(source).toHashSet()
        return words.count { it in sourceWords } * 2 >= words.size
    }

    private fun coverWords(text: String): List<String> =
        COVER_WORD.findAll(text.lowercase(Locale.ROOT)).map { it.value }.filter { it.length >= 2 }.toList()

    private fun publish(items: List<CoverItem>): List<CoverItem>? {
        if (items == published) return null
        published = items
        return items
    }

    companion object {
        const val DEFAULT_MISS_MILLIS = 800L
        const val DEFAULT_CONFIRM_FRAMES = 2
        private const val LIVE_KEY_PREFIX = "live:"
        private const val MOVE_LINES = 0.5f
        private const val RESIZE_RATIO = 0.25f
        private const val SAME_PLACE_LINES = 0.5f
    }
}

/**
 * OCR may split one subtitle row into two lines at a button icon ("Hold" and
 * "to view…"); a line beside the previous one on the same row continues it.
 */
private fun sameRowNeighbour(previous: CoverBox, line: CoverBox, typicalHeight: Float): Boolean {
    val overlap = min(previous.bottom, line.bottom) - max(previous.top, line.top)
    val gap = max(line.left - previous.right, previous.left - line.right)
    return overlap >= min(previous.height, line.height) * 0.5f && gap >= 0f && gap <= typicalHeight * SAME_ROW_GAP_LINES
}

/** Rows top to bottom, each row left to right. */
private fun readingOrder(lines: List<CoverLine>): List<CoverLine> {
    val rows = ArrayList<MutableList<CoverLine>>()
    for (line in lines.sortedBy { it.box.top }) {
        val row = rows.lastOrNull()?.takeIf { row -> abs(row.first().box.centerY - line.box.centerY) <= row.first().box.height * 0.5f }
        if (row != null) row.add(line) else rows.add(mutableListOf(line))
    }
    return rows.flatMap { row -> row.sortedBy { it.box.left } }
}

private const val SAME_ROW_GAP_LINES = 3.5f
private const val NEW_SUBTITLE_GAP_LINES = 0.8f
private val COVER_WORD = Regex("""[\p{L}\p{N}]+""")
private val COVER_SPEAKER_LABEL = Regex("""^\s*[-–—]?\s*\p{Lu}[\p{L}\p{N} .’'-]{0,24}:\s*\S""")
