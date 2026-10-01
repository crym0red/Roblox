# FunnyExecutor iOS — safe dylib skeleton + local executor panel

This package is a standalone arm64 iOS dynamic-library project.

Included:
- `iOS/include/ExecutorKit.h`
- `iOS/include/ExecutorOverlay.h`
- `iOS/ExecutorKit/ExecutorKit.c`
- `iOS/ExecutorKit/ExecutorOverlay.m`
- `build.sh`
- selected original UI/reference files from FunnyExecutor

## Three-finger executor panel

The dylib installs a compact UIKit overlay into the host app. It stays hidden during normal use.

- **Three-finger hold:** show the panel.
- **Three-finger hold again:** hide the panel.
- **Editor tab:** local script editor.
- **Console tab:** execution/output console.
- **Library tab:** simple in-memory saved-script list.
- **Execute:** calls the existing `FE_ExecuteLocal()` local-runtime bridge.
- **Clear:** clears the editor.

The overlay does not add Roblox process injection, memory modification, bytecode replacement, or third-party client execution. `FE_ExecuteLocal()` remains the bridge for a runtime that the host app owns or controls.

Build on macOS with Xcode command-line tools:

    chmod +x build.sh
    ./build.sh build

Output:
    build/ExecutorKit.dylib

## GitHub Actions

The repository includes `.github/workflows/build.yml`, which builds the arm64 dylib on a macOS runner and uploads `ExecutorKit-ios-arm64.zip` as a workflow artifact.
