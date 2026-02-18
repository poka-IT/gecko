# Gecko CI - Linux desktop builder
# Used by: build:linux
# Reads Flutter version from .fvmrc automatically
FROM buildpack-deps:jammy

ARG DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/flutter/bin:${PATH}"

# Install clang-17 from LLVM repo (clang-14 from Jammy segfaults on ARM64 with crashpad)
# llvm/lld: needed by Flutter's native assets system
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git unzip xz-utils zip libglu1-mesa gnupg ca-certificates \
    llvm lld cmake ninja-build pkg-config \
    libgtk-3-dev liblzma-dev libstdc++-12-dev libasound2-dev libpulse-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-good1.0-dev \
    libgstreamer-plugins-bad1.0-dev libsecret-1-dev libcurl4-openssl-dev openjdk-11-jdk \
  && curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor -o /usr/share/keyrings/llvm.gpg \
  && echo "deb [signed-by=/usr/share/keyrings/llvm.gpg] http://apt.llvm.org/jammy/ llvm-toolchain-jammy-17 main" \
     > /etc/apt/sources.list.d/llvm-17.list \
  && apt-get update && apt-get install -y --no-install-recommends clang-17 \
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
