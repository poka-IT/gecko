# Gecko CI - Linux desktop builder
# Used by: build:linux
# Reads Flutter version from .fvmrc automatically
FROM buildpack-deps:jammy

ARG DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/flutter/bin:${PATH}"

# clang/llvm/lld: needed by Flutter's native assets (used via /usr/lib/llvm-14/bin/)
# gcc/g++: used for the main CMake/ninja build (clang segfaults on ARM64 with crashpad)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git unzip xz-utils zip libglu1-mesa \
    clang llvm lld gcc g++ cmake ninja-build pkg-config \
    libgtk-3-dev liblzma-dev libstdc++-12-dev libasound2-dev libpulse-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-good1.0-dev \
    libgstreamer-plugins-bad1.0-dev libsecret-1-dev libcurl4-openssl-dev openjdk-11-jdk \
  && rm -rf /var/lib/apt/lists/* \
  && JAVA_DIR=$(find /usr/lib/jvm -name "java-11-openjdk-*" -maxdepth 1 -type d | head -1) \
  && ln -sfn "$JAVA_DIR" /usr/lib/jvm/java-11-openjdk \
  && rm -f /usr/bin/clang /usr/bin/clang++ /usr/bin/cc /usr/bin/c++ \
  && ln -s /usr/bin/gcc /usr/bin/cc \
  && ln -s /usr/bin/g++ /usr/bin/c++

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk
ENV CC=gcc CXX=g++

COPY .fvmrc /tmp/.fvmrc

RUN FLUTTER_VERSION=$(cat /tmp/.fvmrc | grep -o '"flutter": "[^"]*"' | cut -d'"' -f4) \
  && echo "Installing Flutter version: $FLUTTER_VERSION" \
  && git clone https://github.com/flutter/flutter.git -b $FLUTTER_VERSION --depth 1 /opt/flutter \
  && flutter config --no-analytics \
  && flutter precache --linux \
  && rm /tmp/.fvmrc

WORKDIR /workspace
ENTRYPOINT [""]
