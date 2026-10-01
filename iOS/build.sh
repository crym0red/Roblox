#!/bin/sh
set -eu

SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
OUT="${1:-build}"

rm -rf "$OUT"
mkdir -p "$OUT"

xcrun --sdk iphoneos clang \
  -arch arm64 \
  -isysroot "$SDK" \
  -fobjc-arc \
  -O2 \
  -Wall -Wextra \
  -I iOS/include \
  -dynamiclib \
  iOS/ExecutorKit/ExecutorKit.c \
  iOS/ExecutorKit/ExecutorOverlay.m \
  -framework Foundation \
  -framework UIKit \
  -o "$OUT/ExecutorKit.dylib" \
  -install_name @rpath/ExecutorKit.dylib

mkdir -p "$OUT/ExecutorKit.framework/Headers"
cp "$OUT/ExecutorKit.dylib" "$OUT/ExecutorKit.framework/ExecutorKit"
cp iOS/include/ExecutorKit.h "$OUT/ExecutorKit.framework/Headers/ExecutorKit.h"
cp iOS/include/module.modulemap "$OUT/ExecutorKit.framework/Headers/module.modulemap"

echo "Built $OUT/ExecutorKit.dylib"
