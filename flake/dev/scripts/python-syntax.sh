# shellcheck shell=bash
cache=$(mktemp -d)
trap 'rm -rf -- "$cache"' EXIT
PYTHONPYCACHEPREFIX="$cache" python3 -m compileall -q fuzz site
