# Gecko CI - Linux desktop builder
# Used by: build:linux
# Reads Flutter version from .fvmrc automatically
#
# Based on Ubuntu 20.04 (focal) for maximum GLIBC compatibility (2.31).
# This ensures binaries run on Debian 11+, Ubuntu 20.04+, Fedora 33+, etc.
FROM buildpack-deps:focal

ARG DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/flutter/bin:${PATH}"

# Install clang-17 from LLVM repo (needed by Flutter's native assets system)
# Use libstdc++-10-dev (focal's latest available version)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git unzip xz-utils zip libglu1-mesa gnupg ca-certificates software-properties-common \
    cmake ninja-build pkg-config \
    libgtk-3-dev liblzma-dev libstdc++-10-dev libasound2-dev libpulse-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-good1.0-dev \
    libgstreamer-plugins-bad1.0-dev libsecret-1-dev libcurl4-openssl-dev openjdk-11-jdk \
  && curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor -o /usr/share/keyrings/llvm.gpg \
  && echo "deb [signed-by=/usr/share/keyrings/llvm.gpg] http://apt.llvm.org/focal/ llvm-toolchain-focal-17 main" \
     > /etc/apt/sources.list.d/llvm-17.list \
  && apt-get update && apt-get install -y --no-install-recommends clang-17 lld-17 llvm-17 \
  && ln -sf /usr/bin/clang-17 /usr/bin/clang \
  && ln -sf /usr/bin/clang++-17 /usr/bin/clang++ \
  && rm -rf /var/lib/apt/lists/* \
  && JAVA_DIR=$(find /usr/lib/jvm -name "java-11-openjdk-*" -maxdepth 1 -type d | head -1) \
  && ln -sfn "$JAVA_DIR" /usr/lib/jvm/java-11-openjdk

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk

COPY .fvmrc /tmp/.fvmrc

RUN FLUTTER_VERSION=$(cat /tmp/.fvmrc | grep -o '"flutter": "[^"]*"' | cut -d'"' -f4) \
  && echo "Installing Flutter version: $FLUTTER_VERSION" \
  && git clone https://github.com/flutter/flutter.git -b $FLUTTER_VERSION --depth 1 /opt/flutter \
  && flutter config --no-analytics \
  && flutter precache --linux \
  && rm /tmp/.fvmrc

WORKDIR /workspace
ENTRYPOINT [""]
