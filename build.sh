#!/bin/bash

set -euo pipefail

ORCA_DIR=../..
STDLIB_DIR=$ORCA_DIR/src/libc-shim

zig build-lib -fno-sanitize-c -cflags --target=wasm32-freestanding --no-standard-libraries -fno-builtin -Xlinker --no-entry -Xlinker --export-dynamic -g -O2 -mbulk-memory -fno-sanitize=undefined -- -fno-sanitize-c src/main.zig -target wasm32-freestanding -dynamic -mcpu=generic+bulk_memory -rdynamic -D__ORCA__ -isystem $STDLIB_DIR/include -I $ORCA_DIR/src -I $ORCA_DIR/src/ext -femit-bin=module.wasm $ORCA_DIR/src/orca.c $STDLIB_DIR/src/*.c

orca bundle --orca-dir $ORCA_DIR --name UI --resource-dir data module.wasm
