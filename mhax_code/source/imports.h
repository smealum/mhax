#ifndef IMPORTS_H
#define IMPORTS_H

#include <ctr/types.h>

#include "../../build/constants.h"

// handles
Handle* const fsHandle = (Handle*)MCOPY_FS_HANDLE;
Handle* const dspHandle = (Handle*)MCOPY_DSP_HANDLE;
Handle* const gspHandle = (Handle*)MCOPY_GSPGPU_HANDLE;

// buffers
u32** const sharedGspCmdBuf = (u32**)(MCOPY_GSPGPU_INTERRUPT_RECEIVER_STRUCT + 0x58);

// functions
Result (* const _GSPGPU_FlushDataCache)(Handle* handle, Handle kprocess, u32* addr, u32 size) = (void*)MCOPY_GSPGPU_FLUSHDATACACHE;
Result (* const _GSPGPU_GxTryEnqueue)(u32** sharedGspCmdBuf, u32* cmdAdr) = (void*)MCOPY_GSPGPU_GXTRYENQUEUE;
Result (* const _FSUSER_OpenFileDirectly)(Handle* handle, Handle* fileHandle, u32 transaction, u32 archiveId, u32 archivePathType, char* archivePath, u32 archivePathLength, u32 filePathType, char* filePath, u32 filePathLength, u8 openflags, u32 attributes) = (void*)MCOPY_FSUSER_OPENFILEDIRECTLY;
Result (* const _FSUSER_ReadFile)(Handle* handle, u32* bytesRead, s64 offset, void *buffer, u32 size) = (void*)MCOPY_FSUSER_READ;
Result (* const _FSUSER_CloseFile)(Handle* handle) = (void*)MCOPY_FSUSER_CLOSE;
Result (* const _DSP_UnloadComponent)(Handle* handle) = (void*)MCOPY_DSP_UNLOADCOMPONENT;
Result (* const _DSP_RegisterInterruptEvents)(Handle* handle, Handle event, u32 type, u32 port) = (void*)MCOPY_DSP_REGISTERINTERRUPTEVENTS;

#endif
