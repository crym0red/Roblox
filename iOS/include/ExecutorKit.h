#pragma once
#include <stdint.h>


#ifdef __cplusplus
extern "C" {
#endif

typedef void (*FELogCallback)(const char *message);

void FE_SetLogCallback(FELogCallback callback);
int32_t FE_ExecuteLocal(const char *script);
void FE_Clear(void);

#ifdef __cplusplus
}
#endif
