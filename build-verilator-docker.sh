#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT="${SCRIPT_DIR}"
WORKS_DIR=${WORKS_DIR:-"${PROJECT_ROOT}/works"}
SOURCE_DIR=${SOURCE_DIR:-"${WORKS_DIR}/verilator"}
OUTPUT_DIR=${OUTPUT_DIR:-"${WORKS_DIR}/release"}
IMAGE_TAG=${IMAGE_TAG:-local/verilator-buildenv}
RUN_TESTS=${RUN_TESTS:-0}
VERILATOR_REPO_URL=${VERILATOR_REPO_URL:-https://github.com/verilator/verilator.git}
VERILATOR_REF=${VERILATOR_REF:-}
INSTALL_SCRIPT_URL=${INSTALL_SCRIPT_URL:-}

show_help() {
  cat <<EOF
Usage: ./build-verilator-docker.sh [test] [--help] [-- <container args>]

Build Verilator inside Docker and stage the installed tree into a local release directory.

Environment overrides:
  WORKS_DIR           Parent directory for default source/output paths
  SOURCE_DIR          Existing Verilator checkout to build
  OUTPUT_DIR          Destination directory for installed artifacts
  IMAGE_TAG           Docker image tag to build and run
  VERILATOR_REPO_URL  Git URL used when auto-cloning Verilator
  VERILATOR_REF       Optional branch or tag to clone
  INSTALL_PREFIX      Prefix used inside the container build
  CONFIGURE_ARGS      Extra arguments passed to ./configure
  MAKEFLAGS           Flags passed to make
  INSTALL_SCRIPT_URL  Raw URL printed for curl-based local install

Examples:
  ./build-verilator-docker.sh
  ./build-verilator-docker.sh test
  WORKS_DIR="\$HOME/tmp/verilator-work" ./build-verilator-docker.sh
  SOURCE_DIR="\$HOME/src/verilator" OUTPUT_DIR="\$HOME/out/verilator" ./build-verilator-docker.sh
EOF
}

clone_verilator() {
  mkdir -p "${WORKS_DIR}"
  if [[ -n "${VERILATOR_REF}" ]]; then
    git clone --depth 1 --branch "${VERILATOR_REF}" "${VERILATOR_REPO_URL}" "${SOURCE_DIR}"
  else
    git clone --depth 1 "${VERILATOR_REPO_URL}" "${SOURCE_DIR}"
  fi
}

github_raw_install_url() {
  local remote_url owner repo

  if ! remote_url=$(git -C "${PROJECT_ROOT}" remote get-url origin 2>/dev/null); then
    return 1
  fi

  if [[ "${remote_url}" =~ ^https://github\.com/([^/]+)/([^/]+?)(\.git)?$ ]]; then
    owner=${BASH_REMATCH[1]}
    repo=${BASH_REMATCH[2]}
  elif [[ "${remote_url}" =~ ^git@github\.com:([^/]+)/([^/]+?)(\.git)?$ ]]; then
    owner=${BASH_REMATCH[1]}
    repo=${BASH_REMATCH[2]}
  else
    return 1
  fi

  printf 'https://raw.githubusercontent.com/%s/%s/main/install-local.sh\n' "${owner}" "${repo}"
}

extra_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    test)
      RUN_TESTS=1
      shift
      ;;
    --)
      shift
      extra_args+=("$@")
      break
      ;;
    *)
      extra_args+=("$1")
      shift
      ;;
  esac
done

if [[ ! -d "${SOURCE_DIR}" ]]; then
  printf 'Cloning Verilator into %s\n' "${SOURCE_DIR}"
  clone_verilator
elif [[ ! -f "${SOURCE_DIR}/configure.ac" ]]; then
  printf 'Source directory does not look like a Verilator checkout: %s\n' "${SOURCE_DIR}" >&2
  exit 1
fi

mkdir -p "${OUTPUT_DIR}"

docker build \
  -t "${IMAGE_TAG}" \
  -f "${PROJECT_ROOT}/Dockerfile" \
  "${PROJECT_ROOT}"

docker run --rm -t \
  --user "$(id -u):$(id -g)" \
  -e HOME=/tmp/home \
  -e RUN_TESTS="${RUN_TESTS}" \
  -e INSTALL_PREFIX="${INSTALL_PREFIX:-/opt/verilator}" \
  -e SOURCE_DIR=/workspace/source \
  -e OUTPUT_DIR=/workspace/release \
  -e CONFIGURE_ARGS="${CONFIGURE_ARGS:-}" \
  -e MAKEFLAGS="${MAKEFLAGS:--j$(nproc)}" \
  -v "${SOURCE_DIR}:/workspace/source:ro" \
  -v "${OUTPUT_DIR}:/workspace/release" \
  "${IMAGE_TAG}" "${extra_args[@]}"

printf '\nInstall to ~/.local with:\n'
printf '  "%s/install-local.sh" "%s"\n' "${PROJECT_ROOT}" "${OUTPUT_DIR}"
if [[ -n "${INSTALL_SCRIPT_URL}" ]]; then
  printf '\nOr with curl:\n'
  printf '  curl -fsSL "%s" | bash -s -- "%s"\n' "${INSTALL_SCRIPT_URL}" "${OUTPUT_DIR}"
elif INSTALL_SCRIPT_URL=$(github_raw_install_url); then
  printf '\nOr with curl:\n'
  printf '  curl -fsSL "%s" | bash -s -- "%s"\n' "${INSTALL_SCRIPT_URL}" "${OUTPUT_DIR}"
fi
printf '\nThis keeps Verilator binaries in ~/.local/bin and support files in ~/.local/share/verilator.\n'
