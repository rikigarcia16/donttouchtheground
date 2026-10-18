#!/usr/bin/env python3
"""Validates property names used in `new("ClassName", { Prop = ... })` calls
(the UI/visual helpers) against the Roblox API declared in globalTypes.d.luau.
The Luau type checker cannot see through these dictionary-style constructors."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
defs = (ROOT / "globalTypes.d.luau").read_text()

classes = {}
for match in re.finditer(r"^declare class (\w+)(?: extends (\w+))?\n(.*?)^end", defs, re.S | re.M):
    name, parent, body = match.group(1), match.group(2), match.group(3)
    props = set(re.findall(r"^\s+(\w+)\s*:", body, re.M))
    classes[name] = (parent, props)

def props_of(name):
    out = set()
    while name in classes:
        parent, props = classes[name]
        out |= props
        name = parent
    return out

pattern = re.compile(r'new\("(\w+)",\s*\{')
errors = 0
for path in sorted((ROOT / "src").rglob("*.luau")):
    text = path.read_text()
    for match in pattern.finditer(text):
        cls = match.group(1)
        if cls not in classes:
            print(f"{path.relative_to(ROOT)}: unknown class {cls}")
            errors += 1
            continue
        # Extract the table literal up to its matching brace.
        i, depth = match.end(), 1
        while depth and i < len(text):
            ch = text[i]
            depth += ch == "{"
            depth -= ch == "}"
            i += 1
        body = text[match.end(): i - 1]
        # Top-level keys only (strip nested tables/calls).
        flat, depth = [], 0
        for ch in body:
            if ch in "{(":
                depth += 1
            elif ch in "})":
                depth -= 1
            elif depth == 0:
                flat.append(ch)
        keys = re.findall(r"(?:^|,)\s*(\w+)\s*=", "".join(flat))
        valid = props_of(cls) | {"Parent", "Name"}
        line = text.count("\n", 0, match.start()) + 1
        for key in keys:
            if key not in valid:
                print(f"{path.relative_to(ROOT)}:{line}: {cls} has no property '{key}'")
                errors += 1
print(f"checked property tables: {errors} error(s)")
sys.exit(1 if errors else 0)
