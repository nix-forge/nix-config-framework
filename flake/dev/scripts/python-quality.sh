# shellcheck shell=bash
# The builder supplies sourcePath, TMPDIR and out.
# shellcheck disable=SC2154
set -euo pipefail
cd "$sourcePath"
export RUFF_CACHE_DIR="$TMPDIR/ruff-cache"
export PYTHONPYCACHEPREFIX="$TMPDIR/python-pycache"
ruff check --no-fix .
ruff format --check .
ty check --project . --python "$(command -v python3)"
python3 -m compileall -q .
touch "$out"
