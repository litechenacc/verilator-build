# Verilator Docker build env

This image builds a Verilator checkout inside Docker and installs the result into a local release directory.

The default repository layout is:

```text
verilator-build/
  Dockerfile
  build-verilator-docker.sh
  container-build.sh
  works/
    verilator/
    release/
```

## Usage

```bash
./build-verilator-docker.sh
```

If `works/verilator` does not exist yet, the script clones `https://github.com/verilator/verilator.git` automatically.

Run the self-tests too:

```bash
./build-verilator-docker.sh test
```

## Behavior

- Uses the repository root as the Docker build context so `Dockerfile` can copy `container-build.sh`
- Clones Verilator into `works/verilator` automatically when the source checkout is missing
- Mounts the source and release directories individually into the container
- Copies the mounted source checkout to a temporary build directory inside the container
- Installs the built artifacts into `works/release` by default
- Leaves the source checkout untouched aside from Docker reading it

## Optional overrides

```bash
CONFIGURE_ARGS="--enable-longtests" MAKEFLAGS="-j8" ./build-verilator-docker.sh test
```

Common overrides:

```bash
WORKS_DIR="$HOME/tmp/verilator-work" VERILATOR_REF=master ./build-verilator-docker.sh
SOURCE_DIR="$HOME/src/verilator" OUTPUT_DIR="$HOME/out/verilator" ./build-verilator-docker.sh
INSTALL_PREFIX=/usr/local ./build-verilator-docker.sh
```

## Install locally

Best practice is to keep the installed prefix layout under `~/.local/` rather than copying only the binaries into `~/.local/bin`, because Verilator also needs files in `share/verilator/`.

Install the completed build with:

```bash
./install-local.sh
```

Or point it at a specific build output:

```bash
./install-local.sh /path/to/release
```

After this repo is published on GitHub, the installer can also be run directly with curl:

```bash
curl -fsSL https://raw.githubusercontent.com/litechenacc/verilator-build/main/install-local.sh | bash -s -- "$PWD/works/release"
```

This gives you:

- `~/.local/bin/verilator`
- `~/.local/share/verilator/...`

Make sure `~/.local/bin` is on your `PATH`.

## Resume notes

- Current status: the Docker image build was validated successfully, but the first full Verilator build run was interrupted before completion.
- Safe restart: rerun `./build-verilator-docker.sh` and it will start a fresh container build flow.
- Output behavior: the container removes and recreates `works/release` only after `make install` completes, so an interrupted run should not leave a partial staged install there.
- To continue later with tests enabled, run `./build-verilator-docker.sh test`.
- If you want longer developer-style coverage later, run `CONFIGURE_ARGS="--enable-longtests" ./build-verilator-docker.sh test`.
