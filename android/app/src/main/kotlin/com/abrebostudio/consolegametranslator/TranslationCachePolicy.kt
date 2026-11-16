package com.abrebostudio.consolegametranslator

internal data class TranslationCachePolicy(
    val maxEntries: Int = 50_000,
    val days: Int = 90,
    val maxMiB: Int = 32,
) {
    init {
        require(maxEntries in 1_000..50_000 && days in 7..180 && maxMiB in 4..32) { "Invalid cache limits" }
    }
    val maxBytes: Long get() = maxMiB * 1024L * 1024
    val maxAgeMs: Long get() = days * 24L * 60 * 60 * 1000
    fun toMap(): Map<String, Int> = mapOf("maxEntries" to maxEntries, "days" to days, "maxMiB" to maxMiB)

    companion object {
        fun fromMap(value: Map<*, *>): TranslationCachePolicy {
            fun integer(name: String): Int {
                val number = value[name] as? Number ?: error("Invalid cache limits")
                require(number.toDouble().isFinite() && number.toDouble() == number.toInt().toDouble())
                return number.toInt()
            }
            return TranslationCachePolicy(integer("maxEntries"), integer("days"), integer("maxMiB"))
        }
    }
}
