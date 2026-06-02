# Gecko CI - Format checker (~300MB)
# Used by: format job (dart format --set-exit-if-changed lib)
# Dart 3.12 ships with Flutter 3.44.1 (matches .fvmrc) and the project SDK floor (>=3.10.0).
FROM dart:3.12

WORKDIR /workspace
CMD ["/bin/bash"]
