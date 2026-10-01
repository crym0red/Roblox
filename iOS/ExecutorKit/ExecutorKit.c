#include "ExecutorKit.h"
#include <stdio.h>
#include <string.h>

static FELogCallback g_callback = 0;

void FE_SetLogCallback(FELogCallback callback) {
    g_callback = callback;
}

static void log_message(const char *message) {
    if (g_callback) {
        g_callback(message);
    }
}

int32_t FE_ExecuteLocal(const char *script) {
    if (!script || !*script) {
        log_message("No script supplied.");
        return -1;
    }

    /*
     Safe local bridge:
     This intentionally does not attach to Roblox, inject into another
     process, modify memory, or execute code inside a third-party client.
     Replace this function only with a runtime you own/control.
    */
    log_message("Local execution request received.");
    return 0;
}

void FE_Clear(void) {
    log_message("Runtime cleared.");
}
