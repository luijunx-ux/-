from __future__ import annotations

import re
from pathlib import Path

import tomllib

ROOT = Path(__file__).resolve().parents[1]


def require_match(label: str, actual: str, expected: str) -> None:
    if actual != expected:
        raise SystemExit(f"{label} version mismatch: expected {expected!r}, got {actual!r}")


def main() -> None:
    release_version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
    if not re.fullmatch(r"\d+\.\d+\.\d+-alpha\.\d+", release_version):
        raise SystemExit(f"VERSION is not an Alpha semantic version: {release_version!r}")

    pyproject = tomllib.loads((ROOT / "backend" / "pyproject.toml").read_text(encoding="utf-8"))
    require_match("backend", pyproject["project"]["version"], release_version)

    version_module = (ROOT / "backend" / "app" / "core" / "version.py").read_text(
        encoding="utf-8"
    )
    api_match = re.search(r'^APP_VERSION = "([^"]+)"$', version_module, re.MULTILINE)
    if api_match is None:
        raise SystemExit("backend API version constant is missing")
    require_match("API", api_match.group(1), release_version)

    pubspec = (ROOT / "frontend" / "pubspec.yaml").read_text(encoding="utf-8")
    flutter_match = re.search(r"^version:\s*([^+\s]+)\+(\d+)$", pubspec, re.MULTILINE)
    if flutter_match is None:
        raise SystemExit("Flutter version or numeric build number is missing")
    require_match("Flutter", flutter_match.group(1), release_version)
    if int(flutter_match.group(2)) < 2:
        raise SystemExit("Flutter build number must be greater than the previous build number 1")

    compose = (ROOT / "infrastructure" / "docker" / "docker-compose.prod.yml").read_text(
        encoding="utf-8"
    )
    expected_image = f"tianrenlu-backend:{release_version}"
    if expected_image not in compose:
        raise SystemExit(f"default backend image must contain {expected_image!r}")

    print(f"release-version-ok: {release_version}")


if __name__ == "__main__":
    main()
