package com.abrebostudio.consolegametranslator

/** All currently published English-source tiny LiteRT packs supported by this engine. */
internal data class OfflineModelPack(
    val target: String,
    val label: String,
    val repository: String,
    val revision: String,
    val sha256: String,
    val directoryName: String,
    val bytes: Long = 20_144_264L,
)

internal object OfflineMarianCatalog {
    val packs = listOf(
        OfflineModelPack("tr", "Türkçe", "Helsinki-NLP/opus-mt_tiny_eng-tur", "32dca174fe084ee339100534c34b0bd2ddb3b0ea", "6bab379f1f20f8ba927a1494603dcaca25e1882d5f83c2efecfb71060d7ac723", "opus-mt-tiny-eng-tur-32dca174fe08"),
        OfflineModelPack("de", "Almanca", "Helsinki-NLP/opus-mt_tiny_eng-deu", "4847728f444dbb6536d47ecf796579a5a2c940c7", "6954faa877afba2e804cf6a87ff164e1ad12b9d7f4e8af50357b32b4438cd95d", "local-de-4847728f444d"),
        OfflineModelPack("ca", "Katalanca", "Helsinki-NLP/opus-mt_tiny_eng-cat", "9028c59be7e616dcf9311cafe1ad1d9f8e2e6f5e", "bf617e667876a811232671fbb2dd054202e189071574954296abb9f84f567ef3", "local-ca-9028c59be7e6"),
        OfflineModelPack("fr", "Fransızca", "Helsinki-NLP/opus-mt_tiny_eng-fra", "c260690aae6dff61a0bda312bfb1e0d22c09716f", "bc2057f504af6c5d07ee80abd84e6b617463a75b54f05467d80b9ea99ed3f26f", "local-fr-c260690aae6d"),
        OfflineModelPack("es", "İspanyolca", "Helsinki-NLP/opus-mt_tiny_eng-spa", "2d7f9fd", "22b881ac9cef7a298227f03f4bae5c426791e6317acb47f8c8fe521381c9fdd3", "local-es-2d7f9fd"),
        OfflineModelPack("it", "İtalyanca", "Helsinki-NLP/opus-mt_tiny_eng-ita", "58b98ae", "1bc49043bb3863dee3c40ca7edd68184fbab61f5aa26e07420384faf83d405e8", "local-it-58b98ae"),
        OfflineModelPack("nl", "Felemenkçe", "Helsinki-NLP/opus-mt_tiny_eng-nld", "18891f4", "5c7a52c66881a1e73dc747eaeaa74e13c786e4183be152c846a463547f772d62", "local-nl-18891f4"),
        OfflineModelPack("el", "Yunanca", "Helsinki-NLP/opus-mt_tiny_eng-ell", "a4ac4e4514af2c71a75d0fd0393e9b9f4c86778e", "a43c8d6ded400acdc503613593b440e8232988abd830f7e9ad2e6ed526cd5b72", "local-el-a4ac4e4514af"),
        OfflineModelPack("ru", "Rusça", "Helsinki-NLP/opus-mt_tiny_eng-rus", "4502094b76a7c33666eae47e4ff9151543e15239", "8764c3a42aedbcde2d494a55777d5f2d40955d608e1f4de387df0c3a137adc17", "local-ru-4502094b76a7"),
    )

    val targetCodes: Set<String> = packs.map { it.target }.toSet()

    fun pack(target: String): OfflineModelPack? = packs.firstOrNull { it.target == target }
}
