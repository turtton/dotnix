#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["tomli-w"]
# ///
"""Merge Nix-declared OmniWM settings into the app-managed settings.toml.

Usage: ./merge-settings.py <nix-generated.toml> <target.toml>
"""

import os
import sys
import tempfile
import tomllib

import tomli_w

UNASSIGNED = "Unassigned"


def load(path):
    try:
        with open(path, "rb") as handle:
            return tomllib.load(handle)
    except FileNotFoundError:
        return {}


def deep_merge(current, desired):
    merged = dict(current)
    for key, value in desired.items():
        if isinstance(value, dict) and isinstance(merged.get(key), dict):
            merged[key] = deep_merge(merged[key], value)
        else:
            merged[key] = value
    return merged


def merge_hotkeys(current, desired):
    by_id = {entry["id"]: dict(entry) for entry in current}
    order = [entry["id"] for entry in current]

    declared = {entry["id"] for entry in desired}
    claimed = {entry["binding"] for entry in desired if entry["binding"] != UNASSIGNED}

    # OmniWM rejects a binding set that maps one shortcut to two actions
    # (duplicateBinding), so undeclared actions must yield the keys we claim.
    for hotkey_id, entry in by_id.items():
        if hotkey_id not in declared and entry.get("binding") in claimed:
            entry["binding"] = UNASSIGNED

    for entry in desired:
        if entry["id"] not in by_id:
            order.append(entry["id"])
        by_id[entry["id"]] = dict(entry)

    return [by_id[hotkey_id] for hotkey_id in order]


def write_atomic(target, data):
    directory = os.path.dirname(target)
    os.makedirs(directory, exist_ok=True)
    handle, tmp = tempfile.mkstemp(dir=directory, prefix=".settings.toml.")
    try:
        with os.fdopen(handle, "wb") as stream:
            tomli_w.dump(data, stream)
        os.chmod(tmp, 0o644)
        os.replace(tmp, target)
    except BaseException:
        os.unlink(tmp)
        raise


def main():
    desired_path, target = sys.argv[1], sys.argv[2]

    desired = load(desired_path)
    current = load(target)

    desired_hotkeys = desired.pop("hotkeys", None)
    merged = deep_merge(current, desired)
    if desired_hotkeys is not None:
        merged["hotkeys"] = merge_hotkeys(current.get("hotkeys", []), desired_hotkeys)

    if merged == current:
        print(f"omniwm: {target} already up to date")
        return

    write_atomic(target, merged)
    print(f"omniwm: merged Nix settings into {target}")


if __name__ == "__main__":
    main()
