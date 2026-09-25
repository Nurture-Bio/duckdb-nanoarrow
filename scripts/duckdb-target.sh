#!/usr/bin/env bash
# Prints "<abi> <version>": the DuckDB build this repository targets. Used by the
# Dockerfile (to set the DuckDB version) and by publish.yml (to check the built
# extension's metadata footer before anything is published).
#
# nanoarrow is a C++ extension compiled together with DuckDB's source, so it loads
# only in that exact DuckDB release. The version is the release tag the `duckdb`
# submodule is pinned to; a submodule commit that is not a release tag is an error.
#
# Tags come from `git ls-remote`, not local tags, because actions/checkout does not
# fetch tags for submodules.
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
