ROPDB_VERSIONS = jpn usa
ROPDB_TARGETS = $(addsuffix _ropdb.txt, $(addprefix mhax_ropdb/, $(ROPDB_VERSIONS)))
ROPDB_TARGET = mhax_ropdb/$(MHAX_VERSION)_ropdb.txt

PAYLOAD_TARGET = payload_$(MHAX_VERSION)

SCRIPTS = "scripts"

.PHONY: directories all build/constants clean

all: directories build/constants out/$(PAYLOAD_TARGET).bin
directories:
	@mkdir -p build && mkdir -p build/cro


build/constants: mhax_ropdb/ropdb.txt
	@python $(SCRIPTS)/makeHeaders.py build/constants "MHAX_VERSION=$(MHAX_VERSION)" $^


out/$(PAYLOAD_TARGET).bin: $(wildcard mhax_save/*.s) build/mhax_code.bin
	@cd mhax_payload && make
	@mkdir -p out
	@cp mhax_payload/payload.bin $@


build/mhax_code.bin: mhax_code/mhax_code.bin
	@cp mhax_code/mhax_code.bin build/
mhax_code/mhax_code.bin: $(wildcard mhax_code/source/*)
	@cd mhax_code && make


mhax_ropdb: $(ROPDB_TARGETS)
mhax_ropdb/ropdb.txt: $(ROPDB_TARGET)
	@cp $(ROPDB_TARGET) mhax_ropdb/ropdb.txt
mhax_ropdb/%_ropdb.txt: mhax_ropdb/jpn_ropdb_proto.txt
	@echo building ropDB for mhax version $*...
	@python scripts/portRopDb.py mhax_code_jpn.bin mhax_code_$*.bin 0x00100000 mhax_ropdb/jpn_ropdb_proto.txt mhax_ropdb/$*_ropdb.txt


clean:
	@rm -rf build
	@rm -f mhax_ropdb/ropdb.txt
	@cd mhax_code && make clean
	@cd mhax_payload && make clean
