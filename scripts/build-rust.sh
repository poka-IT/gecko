#!/bin/bash

set -e

MY_PATH="`dirname \"$0\"`"
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"

cd $MY_PATH/..

cargo bd
cargo make android-dev
cargo br

echo -e "\nRust dependencies have been successfully build !"
