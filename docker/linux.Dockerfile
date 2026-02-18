# Gecko CI - Linux desktop builder
# Used by: build:linux
# Reads Flutter version from .fvmrc automatically
FROM buildpack-deps:focal

ARG DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/flutter/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git unzip xz-utils zip libglu1-mesa clang cmake ninja-build pkg-config \
    libgtk-3-dev liblzma-dev libstdc++-9-dev libasound2-dev libpulse-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-good1.0-dev \
    libgstreamer-plugins-bad1.0-dev libsecret-1-dev libcurl4-openssl-dev openjdk-11-jdk \
  && rm -rf /var/lib/apt/lists/*

COPY .fvmrc /tmp/.fvmrc

RUN FLUTTER_VERSION=$(cat /tmp/.fvmrc | grep -o '"flutter": "[^"]*"' | cut -d'"' -f4) \
  && echo "Installing Flutter version: $FLUTTER_VERSION" \
  && git clone https://github.com/flutter/flutter.git -b $FLUTTER_VERSION --depth 1 /opt/flutter \
  && flutter config --no-analytics \
  && flutter precache --linux \
  && rm /tmp/.fvmrc

WORKDIR /workspace
ENTRYPOINT [""]
