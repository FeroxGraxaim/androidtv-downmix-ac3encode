#!/usr/bin/env python3
"""Resolve official Stremio Android TV APKs from catalog.json."""
import json
import sys
from pathlib import Path

ABI_ALIASES = {
    "arm": "armeabi-v7a",
    "armeabi": "armeabi-v7a",
    "armeabi-v7a": "armeabi-v7a",
    "arm64": "arm64-v8a",
    "aarch64": "arm64-v8a",
    "arm64-v8a": "arm64-v8a",
    "x86": "x86",
    "ia32": "x86",
    "x64": "x86_64",
    "amd64": "x86_64",
    "x86_64": "x86_64",
}


def load(root: Path) -> dict:
    return json.loads((root / "catalog.json").read_text())


def canonical_abi(name: str) -> str:
    if name == "all":
        return "all"
    if name not in ABI_ALIASES:
        sys.exit(f"unknown abi {name!r}; use armeabi-v7a, arm64-v8a, x86, x86_64, or all")
    return ABI_ALIASES[name]


def version_entry(cat: dict, version: str) -> dict:
    versions = cat["versions"]
    if version not in versions:
        known = ", ".join(sorted(versions))
        sys.exit(f"no catalog entry for {version}; known: {known}")
    return versions[version]


def url_for(cat: dict, version: str, abi: str, apk: dict) -> str:
    if "url" in apk:
        return apk["url"]
    return cat["url_template"].format(version=version, code=apk["code"], abi=abi)


def emit_apk(cat: dict, version: str, abi: str) -> None:
    ver = version_entry(cat, version)
    abis = ver["abis"]
    if abi not in abis:
        known = ", ".join(abis)
        sys.exit(f"{version} has no {abi} apk; known: {known}")
    apk = abis[abi]
    overlay = ver.get("overlay", version)
    print(f"VERSION={version}")
    print(f"ABI={abi}")
    print(f"CODE={apk['code']}")
    print(f"SHA256={apk['sha256']}")
    print(f"OVERLAY={overlay}")
    print(f"URL={url_for(cat, version, abi, apk)}")
    print(f"FILENAME=com.stremio.one-{version}-{apk['code']}-{abi}.apk")


def main() -> None:
    if len(sys.argv) < 3:
        sys.exit("usage: catalog.py <root> list|abis|apk ...")
    root = Path(sys.argv[1])
    cmd = sys.argv[2]
    cat = load(root)

    if cmd == "default-version":
        print(cat["default_version"])
        return

    if cmd == "list":
        default = cat["default_version"]
        for version, ver in cat["versions"].items():
            mark = " (default)" if version == default else ""
            print(f"{version}{mark}  overlay={ver.get('overlay', version)}")
            for abi, apk in ver["abis"].items():
                print(f"  {abi:12}  {apk['code']}  {url_for(cat, version, abi, apk)}")
        return

    if cmd == "abis":
        version = sys.argv[3]
        print(" ".join(version_entry(cat, version)["abis"]))
        return

    if cmd == "apk":
        version = sys.argv[3]
        abi = canonical_abi(sys.argv[4])
        if abi == "all":
            sys.exit("apk lookup needs a single abi")
        emit_apk(cat, version, abi)
        return

    if cmd == "canonical-abi":
        print(canonical_abi(sys.argv[3]))
        return

    sys.exit(f"unknown command {cmd}")


if __name__ == "__main__":
    main()
