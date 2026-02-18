# Gecko CI - Android builder (~5GB)
# Used by: build:android:apk, build:android:bundle
FROM eclipse-temurin:17-jdk-jammy

ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_VERSION=3.41.1
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH

# System dependencies for Flutter + Android SDK download
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        git curl wget unzip xz-utils libglu1-mesa && \
    rm -rf /var/lib/apt/lists/*

# Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b $FLUTTER_VERSION --depth 1 /opt/flutter && \
    flutter config --no-analytics && \
    flutter precache --android && \
    rm -rf /opt/flutter/.git

# Android SDK: only the components needed by build.gradle
# ndkVersion "28.2.13676358", compileSdk=flutter.compileSdkVersion, build-tools 34
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d $ANDROID_SDK_ROOT/cmdline-tools && \
    mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip && \
    yes | sdkmanager --licenses && \
    sdkmanager \
        "ndk;28.2.13676358" \
        "platforms;android-35" \
        "build-tools;35.0.0" && \
    rm -rf $ANDROID_SDK_ROOT/.temp

# Accept Flutter Android licenses
RUN yes | flutter doctor --android-licenses || true

WORKDIR /workspace
CMD ["/bin/bash"]
