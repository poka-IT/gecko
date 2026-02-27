# Gecko CI - Android builder (~5GB)
# Used by: build:android:apk, build:android:bundle
# Force amd64: Flutter does not ship gen_snapshot for linux-arm64 Android targets
FROM --platform=linux/amd64 eclipse-temurin:17-jdk-jammy

ENV DEBIAN_FRONTEND=noninteractive
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH

# System dependencies for Flutter + Android SDK download
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        git curl wget unzip xz-utils libglu1-mesa && \
    rm -rf /var/lib/apt/lists/*

# Flutter SDK (version read from .fvmrc)
COPY .fvmrc /tmp/.fvmrc
RUN FLUTTER_VERSION=$(cat /tmp/.fvmrc | grep -o '"flutter": "[^"]*"' | cut -d'"' -f4) \
    && echo "Installing Flutter version: $FLUTTER_VERSION" \
    && git clone https://github.com/flutter/flutter.git -b $FLUTTER_VERSION --depth 1 /opt/flutter \
    && flutter config --no-analytics \
    && flutter precache --android \
    && rm /tmp/.fvmrc

# Android SDK: cmdline-tools + platforms + build-tools
# NDK is auto-downloaded by AGP during first build (version from build.gradle)
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d $ANDROID_SDK_ROOT/cmdline-tools && \
    mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip && \
    yes | sdkmanager --licenses && \
    sdkmanager \
        "platforms;android-35" \
        "build-tools;35.0.0" && \
    rm -rf $ANDROID_SDK_ROOT/.temp

# Accept Flutter Android licenses
RUN yes | flutter doctor --android-licenses || true

WORKDIR /workspace
CMD ["/bin/bash"]
