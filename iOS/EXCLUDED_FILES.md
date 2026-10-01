# Excluded original files

These are intentionally not included in the iOS dylib package because they
implement or support Roblox-client injection, process/memory manipulation,
bytecode replacement/extraction, or a Windows-only executor payload:

src/FAPI/__init__.py
src/FAPI/bridge.py
src/FAPI/sdk.py
src/FAPI/offsets.py
src/helpers/dump.py
src/FAPI/fvm/FunnyVM.luau
src/FAPI/luau/init.luau
src/FAPI/luau/init.bin
src/FAPI/luau/compile.exe

src/FAPI/compiler.py is not copied wholesale because it is coupled to the
original executor/runtime pipeline; only a new safe bridge is supplied.

src/main.py is not copied wholesale because it combines UI with the original
Roblox execution/injection worker. Its UI concepts are represented by the
separate iOS architecture instead.
