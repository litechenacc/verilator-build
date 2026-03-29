#!/usr/bin/env bash
set -euo pipefail

set +u
script_source=${BASH_SOURCE[0]-}
set -u

if [[ -n "${script_source}" && "${script_source}" != "bash" ]]; then
  SCRIPT_DIR=$(cd -- "$(dirname -- "${script_source}")" && pwd)
else
  SCRIPT_DIR=$(pwd)
fi
DEFAULT_RELEASE_DIR="${SCRIPT_DIR}/works/release"
RELEASE_DIR=${1:-${RELEASE_DIR:-${DEFAULT_RELEASE_DIR}}}
INSTALL_ROOT=${INSTALL_ROOT:-"${HOME}/.local"}

show_help() {
  cat <<EOF
Usage: ./install-local.sh [release-dir] [--help]

Copy a built Verilator release tree into a local installation prefix.

Arguments:
  release-dir   Built release directory to install from

Environment overrides:
  RELEASE_DIR   Built release directory if no argument is given
  INSTALL_ROOT  Installation prefix, default: \$HOME/.local

Examples:
  ./install-local.sh
  ./install-local.sh /path/to/release
  INSTALL_ROOT="\$HOME/.local/opt/verilator" ./install-local.sh
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  show_help
  exit 0
fi

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
