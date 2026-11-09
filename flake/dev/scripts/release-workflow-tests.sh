# shellcheck shell=bash
# The builder supplies sourcePath and out; Git repositories stay in temporary fixtures.
# shellcheck disable=SC2154
set -euo pipefail
cd "$sourcePath"
export HOME="$TMPDIR/home"
mkdir -p "$HOME"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export PYTHONPYCACHEPREFIX="$TMPDIR/python-pycache"
python3 -m unittest discover -s .github/tests -v
touch "$out"
