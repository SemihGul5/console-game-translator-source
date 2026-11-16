"""Check the actual release DEX for symbols looked up by chiaki-jni.c.

Run after `flutter build appbundle --release`:
    python tool/verify_chiaki_jni.py build/app/outputs/bundle/release/app-release.aab

Also accepts APK files. Uses only Python's standard library and never loads the
native library or contacts a console. Checking compiled definitions (rather
than source or R8 rules) catches removed, renamed and changed JNI signatures.
"""

import struct
import sys
import zipfile


PACKAGE = "Lcom/metallic/chiaki/lib/"
STRING = "Ljava/lang/String;"


def bridge(name):
    return PACKAGE + name + ";"


FIELDS = {
    "ChiakiLog": {"levelMask": "I"},
    "ChiakiNative$CreateResult": {"errorCode": "I", "ptr": "J"},
    "Codec": {"value": "I"},
    "Target": {"value": "I"},
    "ConnectInfo": {
        "ps5": "Z", "host": STRING, "registKey": "[B", "morning": "[B",
        "videoProfile": bridge("ConnectVideoProfile"),
    },
    "ConnectVideoProfile": {
        "width": "I", "height": "I", "maxFPS": "I", "bitrate": "I",
        "codec": bridge("Codec"),
    },
    "ControllerState": {
        "buttons": "I", "l2State": "B", "r2State": "B", "leftX": "S",
        "leftY": "S", "rightX": "S", "rightY": "S",
        "touches": "[" + bridge("ControllerTouch"),
        **dict.fromkeys((
            "gyroX", "gyroY", "gyroZ", "accelX", "accelY", "accelZ",
            "orientX", "orientY", "orientZ", "orientW",
        ), "F"),
    },
    "ControllerTouch": {"x": "S", "y": "S", "id": "B"},
    "DiscoveryServiceOptions": {
        "hostsMax": "J", "hostDropPings": "J", "pingMs": "J",
        "sendAddr": "Ljava/net/InetSocketAddress;",
    },
    "DiscoveryHost$State": dict.fromkeys(
        ("UNKNOWN", "STANDBY", "READY"), bridge("DiscoveryHost$State"),
    ),
    "RegistInfo": {
        "target": bridge("Target"), "host": STRING, "broadcast": "Z",
        "psnOnlineId": STRING, "psnAccountId": "[B", "pin": "I",
    },
    "RegistEventCanceled": {"INSTANCE": bridge("RegistEventCanceled")},
    "RegistEventFailed": {"INSTANCE": bridge("RegistEventFailed")},
}

METHODS = {
    "ChiakiNative": {
        "errorCodeToString": "(I)" + STRING,
        "quitReasonToString": "(I)" + STRING,
        "quitReasonIsError": "(I)Z",
        "videoProfilePreset": "(II" + bridge("Codec") + ")" + bridge("ConnectVideoProfile"),
        "sessionCreate": "(" + bridge("ChiakiNative$CreateResult") + bridge("ConnectInfo")
                         + STRING + "Z" + bridge("Session") + ")V",
        **dict.fromkeys(("sessionFree", "registStop", "registFree", "discoveryServiceFree"), "(J)V"),
        **dict.fromkeys(("sessionStart", "sessionStop", "sessionJoin", "sessionRequestIdr"), "(J)I"),
        "sessionSetSurface": "(JLandroid/view/Surface;)V",
        "sessionSetControllerState": "(J" + bridge("ControllerState") + ")V",
        "sessionSetLoginPin": "(J" + STRING + ")V",
        "discoveryServiceCreate": "(" + bridge("ChiakiNative$CreateResult")
                                  + bridge("DiscoveryServiceOptions") + bridge("DiscoveryService") + ")V",
        "discoveryServiceWakeup": "(J" + STRING + "JZ)V",
        "registStart": "(" + bridge("ChiakiNative$CreateResult") + bridge("RegistInfo")
                       + bridge("ChiakiLog") + bridge("Regist") + ")V",
    },
    "DiscoveryService": {"hostsUpdated": "([" + bridge("DiscoveryHost") + ")V"},
    "DiscoveryHost": {
        "<init>": "(" + bridge("DiscoveryHost$State") + "S" + STRING * 8 + ")V",
    },
    "Session": {
        "eventConnected": "()V", "eventLoginPinRequest": "(Z)V",
        "eventQuit": "(I" + STRING + ")V", "eventRumble": "(II)V",
    },
    "ChiakiLog": {"log": "(I" + STRING + ")V"},
    "Regist": {"event": "(" + bridge("RegistEvent") + ")V"},
    "Target": {"fromValue": "(I)" + bridge("Target")},
    "RegistEventSuccess": {"<init>": "(" + bridge("RegistHost") + ")V"},
    "RegistHost": {
        "<init>": "(" + bridge("Target") + STRING * 4 + "[B" + STRING + "[BI[B)V",
    },
    "ConnectVideoProfile": {"<init>": "(IIII" + bridge("Codec") + ")V"},
}


class Dex:
    def __init__(self, data):
        if not data.startswith(b"dex\n"):
            raise ValueError("Not a DEX file")
        self.data = data
        count, offset = self.unpack("II", 56)
        self.strings = []
        for index in range(count):
            start = self.unpack("I", offset + index * 4)[0]
            _, start = self.uleb(start)
            end = data.index(b"\0", start)
            self.strings.append(data[start:end].decode("utf-8", errors="replace"))
        count, offset = self.unpack("II", 64)
        self.types = [
            self.strings[self.unpack("I", offset + index * 4)[0]]
            for index in range(count)
        ]

    def unpack(self, fmt, offset):
        return struct.unpack_from("<" + fmt, self.data, offset)

    def uleb(self, offset):
        value = 0
        shift = 0
        while True:
            byte = self.data[offset]
            offset += 1
            value |= (byte & 0x7f) << shift
            if byte < 0x80:
                return value, offset
            shift += 7

    def prototype(self, index):
        table = self.unpack("I", 76)[0]
        _, result, params = self.unpack("III", table + index * 12)
        arguments = ""
        if params:
            count = self.unpack("I", params)[0]
            arguments = "".join(
                self.types[self.unpack("H", params + 4 + i * 2)[0]]
                for i in range(count)
            )
        return "(" + arguments + ")" + self.types[result]

    def definitions(self):
        symbols = set()
        count, offset = self.unpack("II", 96)
        for index in range(count):
            definition = self.unpack("IIIIIIII", offset + index * 32)
            owner = self.types[definition[0]]
            position = definition[6]
            if not owner.startswith(PACKAGE):
                continue
            symbols.add(owner)
            if not position:
                continue
            counts = []
            for _ in range(4):
                size, position = self.uleb(position)
                counts.append(size)
            for group, size in enumerate(counts):
                member = 0
                for _ in range(size):
                    delta, position = self.uleb(position)
                    member += delta
                    _, position = self.uleb(position)  # access flags
                    if group < 2:  # static / instance fields
                        table = self.unpack("I", 84)[0]
                        _, field_type, name = self.unpack("HHI", table + member * 8)
                        signature = ":" + self.types[field_type]
                    else:  # direct / virtual methods
                        _, position = self.uleb(position)  # code offset
                        table = self.unpack("I", 92)[0]
                        _, proto, name = self.unpack("HHI", table + member * 8)
                        signature = self.prototype(proto)
                    symbols.add(owner + "." + self.strings[name] + signature)
        return symbols


def main(path):
    expected = set()
    for contract, separator in ((FIELDS, ":"), (METHODS, "")):
        for owner, members in contract.items():
            expected.add(bridge(owner))
            for name, signature in members.items():
                expected.add(bridge(owner) + "." + name + separator + signature)
    actual = set()
    with zipfile.ZipFile(path) as archive:
        dex_files = [name for name in archive.namelist() if name.endswith(".dex")]
        if not dex_files:
            raise ValueError("No DEX files in bundle/APK")
        for name in dex_files:
            actual.update(Dex(archive.read(name)).definitions())
    missing = sorted(expected - actual)
    if missing:
        print(f"FAIL: {len(missing)} of {len(expected)} required Chiaki JNI signatures are missing:")
        for symbol in missing:
            print("  " + symbol)
        return 1
    print(f"PASS: {len(expected)} Chiaki JNI class/member signatures preserved in {path}")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Usage: python tool/verify_chiaki_jni.py <release.aab|release.apk>")
    sys.exit(main(sys.argv[1]))
