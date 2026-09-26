# Builds nanoarrow.duckdb_extension for easy access. publish.yml pushes the result to
# ECR in Shared Services.
ARG BASE_IMAGE=debian:bookworm-slim@sha256:3783cc01769c7b2b1b83a5c5ad96c815348e28ed7da68e2e3687004faa906251

FROM --platform=linux/amd64 ${BASE_IMAGE} AS build
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake python3 python3-venv git ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY . .
# Parallelize by core count. -j1 is only needed when cross-building under QEMU
# (an amd64 image on an arm64 host), where GNU make's jobserver pipe fds break:
# pass --build-arg MAKE_JOBS=1 there. Both knobs are needed: `make release` ends
# in `cmake --build`, which ignores MAKEFLAGS, so CMAKE_BUILD_PARALLEL_LEVEL is
# what parallelizes the C++ compile.
ARG MAKE_JOBS=
RUN set -e; \
    tag=$(scripts/duckdb-target.sh | cut -d' ' -f2); \
    commit=$(git -C duckdb rev-parse HEAD | cut -c1-10); \
    OVERRIDE_GIT_DESCRIBE="${tag}-0-g${commit}" \
    CMAKE_BUILD_PARALLEL_LEVEL="${MAKE_JOBS:-$(nproc)}" MAKEFLAGS="-j${MAKE_JOBS:-$(nproc)}" \
    make release

FROM scratch
COPY --from=build /src/build/release/extension/nanoarrow/nanoarrow.duckdb_extension /ext/
