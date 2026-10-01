#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/// Installs the compact local executor overlay into the current UIKit app.
/// Safe to call more than once.
void FE_InstallExecutorOverlay(void);

/// Removes the overlay and its gesture recognizer if installed.
void FE_RemoveExecutorOverlay(void);

#ifdef __cplusplus
}
#endif
