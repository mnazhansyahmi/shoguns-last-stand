"""Fetch only Windows x64 members from the official Godot template ZIP.

Uses HTTPS byte ranges instead of downloading the full multi-platform archive.
zipfile verifies each selected member's CRC. No third-party Python packages.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path
import urllib.request
import zipfile


class RemoteZip(io.RawIOBase):
    def __init__(self, url: str, length: int):
        self.url, self.length, self.position = url, length, 0

    def seekable(self):
        return True

    def readable(self):
        return True

    def tell(self):
        return self.position

    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else (self.position if whence == 1 else self.length) + offset
        return self.position

    def read(self, size=-1):
        end = self.length if size < 0 else min(self.length, self.position + size)
        if end <= self.position:
            return b""
        request = urllib.request.Request(self.url, headers={
            "Range": f"bytes={self.position}-{end - 1}",
            "User-Agent": "ShogunsLastStand-release-preparation",
        })
        with urllib.request.urlopen(request, timeout=60) as response:
            expected = f"bytes {self.position}-{end - 1}/{self.length}"
            if response.status != 206 or response.headers.get("Content-Range") != expected:
                raise RuntimeError("Server did not honor the requested byte range")
            data = response.read(end - self.position)
        if len(data) != end - self.position:
            raise RuntimeError("Incomplete archive response")
        self.position = end
        return data


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", default="4.7.2")
    parser.add_argument("--out", type=Path, default=Path("builds/export_templates"))
    args = parser.parse_args()
    tag = f"{args.version}-stable"
    api = f"https://api.github.com/repos/godotengine/godot-builds/releases/tags/{tag}"
    request = urllib.request.Request(api, headers={"User-Agent": "ShogunsLastStand-release-preparation"})
    with urllib.request.urlopen(request, timeout=30) as response:
        release = json.load(response)
    asset = next(a for a in release["assets"] if a["name"] == f"Godot_v{tag}_export_templates.tpz")
    args.out.mkdir(parents=True, exist_ok=True)
    manifest = {"version": args.version, "source": asset["browser_download_url"], "members": []}
    with zipfile.ZipFile(RemoteZip(asset["browser_download_url"], asset["size"])) as archive:
        selected = [i for i in archive.infolist() if i.filename.endswith((
            "windows_release_x86_64.exe", "windows_debug_x86_64.exe", "windows_console_wrapper.exe"))]
        if not any(i.filename.endswith("windows_release_x86_64.exe") for i in selected):
            raise RuntimeError("Official archive has no Windows x64 release template")
        for info in selected:
            name = Path(info.filename).name
            data = archive.read(info)
            (args.out / name).write_bytes(data)
            manifest["members"].append({"name": name, "size": len(data),
                "zip_crc32": f"{info.CRC:08x}", "sha256": hashlib.sha256(data).hexdigest()})
            print(f"Verified ZIP CRC and saved {name}: {len(data)} bytes", flush=True)
    (args.out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf8")


if __name__ == "__main__":
    main()
