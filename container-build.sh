#!/usr/bin/env bash
set -euo pipefail

: "${SOURCE_DIR:=/workspace/verilator}"
: "${OUTPUT_DIR:=/workspace/release}"
: "${BUILD_ROOT:=/tmp/verilator-build}"
: "${RUN_TESTS:=0}"
: "${MAKEFLAGS:=-j$(nproc)}"
: "${CONFIGURE_ARGS:=}"
: "${INSTALL_PREFIX:=/opt/verilator}"

if [[ ! -d "${SOURCE_DIR}" ]]; then
    printf 'Missing source directory: %s\n' "${SOURCE_DIR}" >&2
    exit 1
fi

mkdir -p "${HOME:-/tmp/home}"
rm -rf "${BUILD_ROOT}"
mkdir -p "${BUILD_ROOT}/src" "${BUILD_ROOT}/stage"

cp -a "${SOURCE_DIR}/." "${BUILD_ROOT}/src/"

cd "${BUILD_ROOT}/src"
autoconf
./configure --prefix="${INSTALL_PREFIX}" ${CONFIGURE_ARGS}
make ${MAKEFLAGS}

if [[ "${RUN_TESTS}" == "1" ]]; then
    make test
fi

make install DESTDIR="${BUILD_ROOT}/stage"

mkdir -p "${OUTPUT_DIR}"
shopt -s dotglob nullglob
rm -rf -- "${OUTPUT_DIR}"/*
shopt -u dotglob nullglob
cp -a "${BUILD_ROOT}/stage${INSTALL_PREFIX}/." "${OUTPUT_DIR}/"

printf 'Build complete. Installed files are in %s\n' "${OUTPUT_DIR}"
