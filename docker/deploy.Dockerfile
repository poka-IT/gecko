# Gecko CI - Play Store deployer (~400MB)
# Used by: deploy:android:playstore (fastlane supply)
FROM ruby:3-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        build-essential git && \
    gem install fastlane -NV && \
    apt-get purge -y build-essential && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
CMD ["/bin/bash"]
