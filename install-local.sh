#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DEFAULT_RELEASE_DIR="${SCRIPT_DIR}/works/release"
RELEASE_DIR=${1:-${RELEASE_DIR:-${DEFAULT_RELEASE_DIR}}}
INSTALL_ROOT=${INSTALL_ROOT:-"${HOME}/.local"}

if [[ ! -d "${RELEASE_DIR}" ]]; then
  printf 'Missing release directory: %s\n' "${RELEASE_DIR}" >&2
  exit 1
fi

if [[ ! -x "${RELEASE_DIR}/bin/verilator" ]]; then
  printf 'Expected Verilator binary at %s\n' "${RELEASE_DIR}/bin/verilator" >&2
  exit 1
fi

if [[ ! -d "${RELEASE_DIR}/share/verilator" ]]; then
  printf 'Expected support files at %s\n' "${RELEASE_DIR}/share/verilator" >&2
  exit 1
fi

mkdir -p "${INSTALL_ROOT}"
cp -a "${RELEASE_DIR}/." "${INSTALL_ROOT}/"

printf 'Installed Verilator into %s\n' "${INSTALL_ROOT}"
printf 'Binaries: %s\n' "${INSTALL_ROOT}/bin"
printf 'Support files: %s\n' "${INSTALL_ROOT}/share/verilator"
printf 'Ensure %s is on your PATH.\n' "${INSTALL_ROOT}/bin"
printf 'Optional: export VERILATOR_ROOT=%q\n' "${INSTALL_ROOT}/share/verilator"
