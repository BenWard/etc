#!/usr/bin/env python3

import argparse
import json
import os
import re
import sys
import tomllib
from collections.abc import Mapping
from pathlib import Path
from typing import Any


BARE_KEY = re.compile(r"^[A-Za-z0-9_-]+$")


class InitError(Exception):
    pass


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Create or update the machine-local Chezmoi config."
    )
    parser.add_argument(
        "root",
        nargs="?",
        default=Path.cwd(),
        type=Path,
        help="Repository root. Defaults to the current directory.",
    )
    parser.add_argument(
        "--config",
        type=Path,
        default=None,
        help="Local Chezmoi config path. Defaults to $XDG_CONFIG_HOME/chezmoi/chezmoi.toml.",
    )
    args = parser.parse_args()

    root = args.root.resolve()
    config_dir = root / "home" / "dot_config" / "chezmoi"
    example_path = config_dir / "chezmoi.example.toml"
    local_path = args.config.resolve() if args.config is not None else default_config_path()

    try:
        example = load_toml(example_path)
        local = load_toml(local_path) if local_path.exists() else {}
        missing = missing_values(example, local)

        if not missing:
            print(f"Chezmoi local config is up to date: {local_path}")
            return 0

        print("Chezmoi local config")
        print(f"Example: {example_path}")
        print(f"Local:   {local_path}")
        print()

        interactive = sys.stdin.isatty()
        if not interactive:
            print("No interactive terminal detected; accepting defaults for missing values.")
            print()

        updates: dict[tuple[str, ...], Any] = {}
        for path, default in missing:
            label = label_for(path)
            if interactive:
                updates[path] = prompt_value(label, default)
            else:
                updates[path] = default

        merged = merge_values(local, updates)
        validate_supported(merged)
        local_path.parent.mkdir(parents=True, exist_ok=True)
        write_toml(local_path, merged)

        print()
        print(f"Wrote {local_path}")
        for path in updates:
            print(f"  added {format_path(path)}")

        return 0
    except InitError as error:
        print(f"init: {error}", file=sys.stderr)
        return 1


def load_toml(path: Path) -> dict[str, Any]:
    try:
        with path.open("rb") as config_file:
            data = tomllib.load(config_file)
    except FileNotFoundError as error:
        raise InitError(f"missing TOML file: {path}") from error
    except tomllib.TOMLDecodeError as error:
        raise InitError(f"could not parse {path}: {error}") from error

    if not isinstance(data, dict):
        raise InitError(f"{path} did not contain a TOML table")

    return data


def missing_values(
    example: Mapping[str, Any],
    local: Mapping[str, Any],
    prefix: tuple[str, ...] = (),
) -> list[tuple[tuple[str, ...], Any]]:
    missing: list[tuple[tuple[str, ...], Any]] = []

    for key, example_value in example.items():
        path = (*prefix, key)
        local_has_key = key in local
        local_value = local.get(key)

        if isinstance(example_value, Mapping):
            if isinstance(local_value, Mapping):
                missing.extend(missing_values(example_value, local_value, path))
            else:
                missing.extend(flatten_values(example_value, path))
        elif not local_has_key:
            validate_supported_value(path, example_value)
            missing.append((path, example_value))

    return missing


def flatten_values(
    values: Mapping[str, Any],
    prefix: tuple[str, ...],
) -> list[tuple[tuple[str, ...], Any]]:
    flattened: list[tuple[tuple[str, ...], Any]] = []

    for key, value in values.items():
        path = (*prefix, key)
        if isinstance(value, Mapping):
            flattened.extend(flatten_values(value, path))
        else:
            validate_supported_value(path, value)
            flattened.append((path, value))

    return flattened


def prompt_value(label: str, default: Any) -> Any:
    rendered_default = render_value(default)
    response = input(f"{label} [{rendered_default}]: ").strip()

    if response == "":
        return default

    if isinstance(default, bool):
        lowered = response.lower()
        if lowered in {"1", "true", "yes", "y", "on"}:
            return True
        if lowered in {"0", "false", "no", "n", "off"}:
            return False
        raise InitError(f"expected a boolean for {label}")

    if isinstance(default, int) and not isinstance(default, bool):
        try:
            return int(response)
        except ValueError as error:
            raise InitError(f"expected an integer for {label}") from error

    if isinstance(default, float):
        try:
            return float(response)
        except ValueError as error:
            raise InitError(f"expected a number for {label}") from error

    if isinstance(default, list):
        try:
            parsed = tomllib.loads(f"value = {response}")["value"]
        except tomllib.TOMLDecodeError as error:
            raise InitError(f"expected a TOML array for {label}") from error
        validate_supported_value((label,), parsed)
        return parsed

    return response


def merge_values(
    local: Mapping[str, Any],
    updates: Mapping[tuple[str, ...], Any],
) -> dict[str, Any]:
    merged = deep_copy_mapping(local)

    for path, value in updates.items():
        cursor = merged
        for key in path[:-1]:
            current = cursor.get(key)
            if not isinstance(current, dict):
                current = {}
                cursor[key] = current
            cursor = current
        cursor[path[-1]] = value

    return merged


def deep_copy_mapping(values: Mapping[str, Any]) -> dict[str, Any]:
    copied: dict[str, Any] = {}

    for key, value in values.items():
        if isinstance(value, Mapping):
            copied[key] = deep_copy_mapping(value)
        elif isinstance(value, list):
            copied[key] = list(value)
        else:
            copied[key] = value

    return copied


def validate_supported(values: Mapping[str, Any], prefix: tuple[str, ...] = ()) -> None:
    for key, value in values.items():
        path = (*prefix, key)
        if isinstance(value, Mapping):
            validate_supported(value, path)
        else:
            validate_supported_value(path, value)


def validate_supported_value(path: tuple[str, ...], value: Any) -> None:
    if isinstance(value, str | bool | int | float):
        return

    if isinstance(value, list):
        for item in value:
            validate_supported_value(path, item)
        return

    raise InitError(f"unsupported value at {format_path(path)}: {type(value).__name__}")


def write_toml(path: Path, values: Mapping[str, Any]) -> None:
    temp_path = path.with_name(f".{path.name}.tmp")
    temp_path.write_text(render_toml(values), encoding="utf-8")
    temp_path.replace(path)


def render_toml(values: Mapping[str, Any]) -> str:
    lines = [
        "# Machine-local Chezmoi config.",
        "# Created by `just init` from chezmoi.example.toml.",
        "",
    ]
    append_table(lines, (), values)
    return "\n".join(lines).rstrip() + "\n"


def append_table(
    lines: list[str],
    prefix: tuple[str, ...],
    values: Mapping[str, Any],
) -> None:
    scalars = [(key, value) for key, value in values.items() if not isinstance(value, Mapping)]
    tables = [(key, value) for key, value in values.items() if isinstance(value, Mapping)]

    if prefix:
        if lines[-1] != "":
            lines.append("")
        lines.append(f"[{'.'.join(format_key(key) for key in prefix)}]")

    for key, value in scalars:
        if prefix:
            lines.append(f"# {label_for((*prefix, key))}")
        lines.append(f"{format_key(key)} = {render_value(value)}")

    for key, value in tables:
        append_table(lines, (*prefix, key), value)


def render_value(value: Any) -> str:
    if isinstance(value, str):
        return json.dumps(value)
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int | float):
        return str(value)
    if isinstance(value, list):
        return f"[{', '.join(render_value(item) for item in value)}]"

    raise InitError(f"unsupported value: {type(value).__name__}")


def format_key(key: str) -> str:
    if BARE_KEY.match(key):
        return key
    return json.dumps(key)


def format_path(path: tuple[str, ...]) -> str:
    return ".".join(format_key(key) for key in path)


def default_config_path() -> Path:
    config_home = os.environ.get("XDG_CONFIG_HOME")
    if config_home:
        return Path(config_home).expanduser() / "chezmoi" / "chezmoi.toml"
    return Path.home() / ".config" / "chezmoi" / "chezmoi.toml"


def label_for(path: tuple[str, ...]) -> str:
    words = re.sub(r"(?<!^)([A-Z])", r" \1", path[-1]).replace("_", " ").replace("-", " ")
    return f"{format_path(path)} ({words.title()})"


if __name__ == "__main__":
    raise SystemExit(main())
