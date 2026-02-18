# Gecko CI - Format checker (~300MB)
# Used by: format job (dart format --set-exit-if-changed lib)
FROM dart:3.8

WORKDIR /workspace
CMD ["/bin/bash"]
