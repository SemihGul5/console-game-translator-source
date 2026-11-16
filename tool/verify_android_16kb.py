"""Check actual 64-bit ELF LOAD segments in an AAB, APK, AAR or APK set.

Also checks 16 KB ZIP data offsets for uncompressed native libraries in APKs,
including every APK nested in a bundletool .apks file. AAB offsets do not have
to be aligned: bundletool aligns the generated APKs instead.

    python tool/verify_android_16kb.py app-release.aab --require-abi arm64-v8a --require-abi x86_64
    python tool/verify_android_16kb.py app-release.apks

Uses only the Python standard library. Does not execute native code.
"""

import argparse
from collections import Counter
import io
from pathlib import Path
import struct
import sys
import zipfile


PAGE_SIZE = 16384
MACHINES = {"arm64-v8a": 183, "x86_64": 62}


def check_elf(data, abi):
    if data[:6] != b"\x7fELF\x02\x01":
        raise ValueError("expected little-endian ELF64")
    if struct.unpack_from("<H", data, 18)[0] != MACHINES[abi]:
        raise ValueError(f"ELF machine does not match {abi}")
    offset = struct.unpack_from("<Q", data, 32)[0]
    size, count = struct.unpack_from("<HH", data, 54)
    if size < 56 or offset + size * count > len(data):
        raise ValueError("invalid ELF program header table")
    loads = []
    for index in range(count):
        header = struct.unpack_from("<IIQQQQQQ", data, offset + size * index)
        kind, _, file_offset, address, _, file_size, _, alignment = header
        if kind != 1:  # PT_LOAD
            continue
        if file_offset + file_size > len(data):
            raise ValueError("LOAD extends past the file")
        if alignment < PAGE_SIZE or alignment & (alignment - 1):
            raise ValueError(f"LOAD alignment {alignment} is incompatible with 16 KB")
        if (address - file_offset) % PAGE_SIZE:
            raise ValueError("LOAD address and file offset are not congruent modulo 16 KB")
        loads.append(alignment)
    if not loads:
        raise ValueError("no LOAD segments")
    return min(loads)


def data_offset(archive, entry):
    archive.fp.seek(entry.header_offset)
    header = archive.fp.read(30)
    if header[:4] != b"PK\x03\x04":
        raise ValueError("invalid ZIP local file header")
    name_size, extra_size = struct.unpack_from("<HH", header, 26)
    return entry.header_offset + 30 + name_size + extra_size


def check_archive(source, label, is_apk, counts, errors):
    with zipfile.ZipFile(source) as archive:
        for entry in archive.infolist():
            name = entry.filename
            if name.endswith(".apk"):
                check_archive(io.BytesIO(archive.read(entry)), f"{label}!{name}", True, counts, errors)
                continue
            if not name.endswith(".so"):
                continue
            abi = next((part for part in name.split("/") if part in MACHINES), None)
            if abi is None:
                continue
            full_name = f"{label}!{name}"
            try:
                alignment = check_elf(archive.read(entry), abi)
                if is_apk and entry.compress_type == zipfile.ZIP_STORED:
                    offset = data_offset(archive, entry)
                    if offset % PAGE_SIZE:
                        raise ValueError(f"uncompressed APK ZIP data offset {offset} is not 16 KB aligned")
                counts[abi] += 1
                print(f"PASS {full_name}: minimum LOAD alignment = {alignment}")
            except (ValueError, struct.error) as error:
                errors.append(f"{full_name}: {error}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    parser.add_argument("--require-abi", action="append", choices=MACHINES, default=[])
    args = parser.parse_args()
    counts = Counter()
    errors = []
    try:
        check_archive(args.archive, args.archive.name, args.archive.suffix.lower() == ".apk", counts, errors)
    except (OSError, ValueError, zipfile.BadZipFile) as error:
        errors.append(str(error))
    if not counts and not errors:
        errors.append("no supported 64-bit native libraries found")
    for abi in args.require_abi:
        if not counts[abi]:
            errors.append(f"required ABI missing or has no passing libraries: {abi}")
    for error in errors:
        print(f"FAIL {error}", file=sys.stderr)
    print(f"Checked {sum(counts.values())} passing 64-bit libraries: {dict(counts)}; failures: {len(errors)}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
