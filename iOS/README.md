# ExecutorKit iOS dylib

ExecutorKit is a local iOS overlay dylib. It installs a floating executor panel into the active host application.

## UI

The panel is intentionally modeled after a desktop-style executor workspace:

- left navigation sidebar
- top title/status bar
- script tabs
- editor and console panes
- Execute / Clear controls
- compact and maximized layouts
- two-finger pinch to resize
- three-finger hold to show/hide the panel

The existing `FE_ExecuteLocal()` bridge remains the execution boundary.
