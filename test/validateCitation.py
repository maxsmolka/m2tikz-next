#!/usr/bin/env python3
"""Validate YAML syntax and required public fields in CITATION.cff."""

from pathlib import Path
import re
import sys


def load_cff(path: Path) -> dict:
    """Use PyYAML when available; otherwise validate this CFF's safe subset."""
    text = path.read_text(encoding="utf-8")
    try:
        import yaml  # type: ignore
    except ModuleNotFoundError:
        if "\t" in text:
            raise ValueError("tabs are not permitted in the CFF YAML")
        data: dict[str, object] = {}
        for line in text.splitlines():
            if not line or line.startswith(" ") or line.startswith("#"):
                continue
            match = re.fullmatch(r"([a-z][a-z0-9-]*):(?:\s*(.*))?", line)
            if not match:
                raise ValueError(f"unsupported or invalid top-level YAML: {line}")
            key, value = match.groups()
            if value and value.startswith('"'):
                if not value.endswith('"'):
                    raise ValueError(f"unterminated quoted scalar: {key}")
                value = value[1:-1]
            data[key] = value or None
        if not re.search(r"(?m)^authors:\s*\n\s+-\s+(?:name|family-names):", text):
            data["authors"] = []
        else:
            data["authors"] = ["validated-author-entry"]
        return data
    return yaml.safe_load(text)


def main() -> int:
    path = Path(sys.argv[1] if len(sys.argv) > 1 else "CITATION.cff")
    text = path.read_text(encoding="utf-8")
    data = load_cff(path)
    required = {
        "cff-version", "message", "title", "type", "version", "authors",
        "license", "repository-code",
    }
    missing = sorted(required.difference(data or {}))
    if missing:
        raise ValueError(f"missing required CFF fields: {', '.join(missing)}")
    if data["cff-version"] != "1.2.0":
        raise ValueError("citation metadata must use CFF 1.2.0")
    if data["type"] != "software" or data["title"] != "m2tikz-next":
        raise ValueError("citation identity must describe m2tikz-next software")
    if not isinstance(data["authors"], list) or not data["authors"]:
        raise ValueError("authors must be a non-empty sequence")
    if not re.fullmatch(r"0\.[0-9]+\.[0-9]+", str(data["version"])):
        raise ValueError("public version must be a pre-1.0 SemVer release target")
    if data["repository-code"] != "https://github.com/maxsmolka/m2tikz-next":
        raise ValueError("top-level repository-code must identify m2tikz-next")
    if "repository-code: \"https://github.com/matlab2tikz/matlab2tikz\"" not in text:
        raise ValueError("original matlab2tikz repository reference is missing")
    print(f"CITATION validation: PASS ({path}, version {data['version']})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
