package com.abrebostudio.consolegametranslator

import org.junit.Assert.*
import org.junit.Test

class PsnBrokerClientTest {
    @Test fun acceptsOnlyHttpsOrigins() {
        assertEquals("https://psn.example.com", PsnBrokerClient.validateOrigin("https://psn.example.com/"))
        assertEquals("https://psn.example.com", PsnBrokerClient.validateOrigin("https://PSN.example.com:443/"))
        listOf("", "http://psn.example.com", "https://user@psn.example.com", "https://psn.example.com/path",
            "https://psn.example.com?secret=x", "https://psn.example.com#x", "https://psn.example.com:8080").forEach {
            assertThrows(IllegalStateException::class.java) { PsnBrokerClient.validateOrigin(it) }
        }
    }

    @Test fun bindsProofToExactCode() {
        assertEquals("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", PsnBrokerClient.codeDigest("abc"))
        assertNotEquals(PsnBrokerClient.codeDigest("abc"), PsnBrokerClient.codeDigest("abd"))
    }

    @Test fun acceptsExistingEightByteAccountIdFormat() {
        listOf("AQAAAAAAAAA=", "AAAAAAAAAAA=", "//////////8=").forEach {
            assertEquals(it, PsnBrokerClient.parseAccountId("{\"accountId\":\"$it\"}"))
        }
    }

    @Test fun refusesTokensExtraFieldsAndNoncanonicalAccountIds() {
        listOf("{}", "{\"accountId\":1}", "{\"accountId\":\"AQAAAAAAAAA=\",\"access_token\":\"secret\"}",
            "{\"accountId\":\"short\"}", "{\"accountId\":\"AAAAAAAAAAB=\"}", "{\"accountId\":\"AQAAAAAAAAA=\\n\"}").forEach {
            assertThrows(IllegalStateException::class.java) { PsnBrokerClient.parseAccountId(it) }
        }
    }
}
