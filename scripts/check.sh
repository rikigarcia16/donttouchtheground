#!/usr/bin/env bash
# Runs every offline check: format, lint, type-check, unit tests and a place build.
# Tools: rojo, selene, stylua, luau-lsp, lune (see rokit.toml).
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f globalTypes.d.luau ]; then
	curl -sSfL -o globalTypes.d.luau https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/1.53.0/scripts/globalTypes.d.luau
fi

echo "== stylua"; stylua --check src tests
if [ "${SKIP_SELENE:-0}" = "1" ]; then echo "== selene (skipped)"; else echo "== selene"; selene src; fi
echo "== rojo sourcemap"; rojo sourcemap default.project.json -o sourcemap.json
echo "== luau-lsp analyze"
luau-lsp analyze --definitions=globalTypes.d.luau --sourcemap=sourcemap.json --no-strict-dm-types \
	--flag:LuauSolverV2=false --ignore="tests/**" src
echo "== property tables"; python3 scripts/check_props.py
echo "== lune tests"; lune run tests/run.luau
echo "== rojo build"; mkdir -p build && rojo build default.project.json -o build/DontTouchTheGround.rbxl
echo "All checks passed."
