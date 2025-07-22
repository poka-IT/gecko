#!/bin/bash

EXCLUDE_PATTERN="{**/models/widgets_keys.dart,}"

display_help() {
  echo "Usage: $0 [option]"
  echo "Options:"
  echo "  --unused-code       Check unused code in *.dart files"
  echo "  --unused-files      Check unused *.dart files"
  echo "  --unnecessary-null  Check unnecessary nullable parameters in functions, methods, constructors"
}

if [ $# -eq 0 ]; then
  display_help
  exit 0
fi

case "$1" in
  --unused-code)
    dart run dart_code_linter:metrics check-unused-code lib --exclude="$EXCLUDE_PATTERN"
    ;;
  --unused-files)
    dart run dart_code_linter:metrics check-unused-files lib --exclude="$EXCLUDE_PATTERN"
    ;;
  --unnecessary-null)
    dart run dart_code_linter:metrics check-unnecessary-nullable lib --exclude="$EXCLUDE_PATTERN"
    ;;
  *)
    echo "Unknown option: $1"
    display_help
    exit 1
    ;;
esac

