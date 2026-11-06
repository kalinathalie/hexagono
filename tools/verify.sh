#!/bin/bash
# Full check: runs tests/xscw/run.lua and every pi/tests/test_*.py; exit 0 only if all pass.
# Usage: bash tools/verify.sh (from any folder). LUA and PYTHON pick the interpreters;
# when unset, Lua is the first of luajit, lua5.1, lua and Python the first of python3, python with numpy.
set -u

cd "$(dirname "$0")/.." || exit 1
export PYTHONDONTWRITEBYTECODE=1

lua_bin=${LUA:-}
if [ -z "$lua_bin" ]; then
  for c in luajit lua5.1 lua; do
    if command -v "$c" >/dev/null 2>&1; then lua_bin=$c; break; fi
  done
fi

py_bin=${PYTHON:-}
if [ -z "$py_bin" ]; then
  for c in python3 python; do
    if command -v "$c" >/dev/null 2>&1 && "$c" -c "import numpy" >/dev/null 2>&1; then
      py_bin=$c
      break
    fi
  done
fi

if [ -z "$lua_bin" ]; then echo "verify: no Lua interpreter (set LUA)"; fi
if [ -z "$py_bin" ]; then echo "verify: no Python with numpy (set PYTHON)"; fi
if [ -z "$lua_bin" ] || [ -z "$py_bin" ]; then exit 1; fi

failing=0

lua_out=$("$lua_bin" tests/xscw/run.lua 2>&1)
lua_rc=$?
lua_last=$(printf '%s\n' "$lua_out" | tail -n 1)
if [ "$lua_rc" -eq 0 ]; then
  echo "ok   tests/xscw/run.lua: $lua_last"
else
  echo "FAIL tests/xscw/run.lua: ${lua_last:-exit $lua_rc, no output}"
  [ -n "$lua_out" ] && printf '%s\n' "$lua_out"
  failing=$((failing + 1))
fi

for t in pi/tests/test_*.py; do
  if py_out=$("$py_bin" "$t" 2>&1); then
    echo "ok   $t"
  else
    echo "FAIL $t"
    printf '%s\n' "$py_out"
    failing=$((failing + 1))
  fi
done

if [ "$failing" -eq 0 ]; then
  echo "verify: OK"
  exit 0
fi
echo "verify: FAILED ($failing failing)"
exit 1
