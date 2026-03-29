FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        autoconf \
        bc \
        bison \
        build-essential \
        ca-certificates \
        ccache \
        clang \
        cmake \
        flex \
        git \
        help2man \
        libfl2 \
        libfl-dev \
        libjemalloc-dev \
        libsystemc \
        libsystemc-dev \
        numactl \
        perl \
        perl-doc \
        python3 \
        python3-distro \
        z3 \
        zlib1g \
        zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY container-build.sh /usr/local/bin/container-build.sh

ENTRYPOINT ["/usr/local/bin/container-build.sh"]
