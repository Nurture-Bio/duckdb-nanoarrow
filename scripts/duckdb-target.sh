#!/usr/bin/env bash
# Prints "<abi> <version>": the DuckDB build this repository targets.
set -euo pipefail

cd "$(dirname "$0")/.."
commit=$(git -C duckdb rev-parse HEAD)

tag=$(git ls-remote --tags https://github.com/duckdb/duckdb |
  awk -v c="$commit" '$1 == c { sub("refs/tags/", "", $2); sub(/\^\{\}$/, "", $2); print $2 }' |
  grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1 || true)

if [ -z "$tag" ]; then
  echo "duckdb submodule is at $commit, which is not a DuckDB release tag" >&2
  exit 1
fi

echo "CPP $tag"
