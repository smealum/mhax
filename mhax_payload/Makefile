all: payload.bin

clean:
	@rm -f payload.bin

payload.bin: mhax_payload.s mhax_constants.s mhax_macros.s mhax_rop.s ../build/mhax_code.bin
	armips mhax_payload.s
