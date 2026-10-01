# FunnyExecutor iOS — safe dylib skeleton

This package is a standalone arm64 iOS dynamic-library project.

Included:
- `iOS/include/ExecutorKit.h`
- `iOS/ExecutorKit/ExecutorKit.c`
- `build.sh`
- selected original UI/reference files from FunnyExecutor

The dylib intentionally does **not** contain Roblox process injection,
memory modification, bytecode replacement, or third-party client execution.
`FE_ExecuteLocal()` is a bridge for a local runtime that you own/control.

Build on macOS with Xcode command-line tools:

    chmod +x build.sh
    ./build.sh

Output:
    build/ExecutorKit.dylib


## GitHub Actions

The repository includes `.github/workflows/build.yml`, which builds the arm64 dylib on a macOS runner and uploads `ExecutorKit-ios-arm64.zip` as a workflow artifact.
