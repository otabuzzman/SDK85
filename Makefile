A85 ?= asm85

Resources/sdk85-0000.bin: sdk85.asm
	$(A85) -b0000:07FF $^
	install -m 0664 $$(basename $@) Resources

Intel/SDK85.SRC: Intel/SDK85.LST
	gawk < $^ > $@ '             \
		$$0~/^ASM8/ { next }      \
		$$0~/^ISIS/ { next }      \
		$$0~/^LOC/ { next }       \
		$$0~/^$$/ { next }         \
		{ if (substr($$0, 25, 1)~/\+/) next } \
		{ print substr($$0, 26) } \
	'

clean:
	rm -f sdk85.hex sdk85-0000.bin
	rm -f sdk85.lst

tidy: clean
	rm -f Resources/sdk85-0000.bin
