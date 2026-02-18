# Gecko CI - Forum publisher (~150MB)
# Used by: publish:forum:apk, publish:forum:complete
FROM python:3-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends git && \
    pip install --no-cache-dir pydiscourse && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
CMD ["/bin/bash"]
