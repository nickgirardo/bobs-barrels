CC = cc65
AS = ca65
LN = ld65

NODE_SCRIPTS ?= scripts

#set this for your output ROM file name
TARGET=game.gtr

EMUPATH=../GameTankEmulator

FLASHTOOL = ../GTFO

SDIR = src
ODIR = build

PORT = COM3

BMPSRC := $(shell find assets -name "*.bmp")
$(info bmpsrc is $(BMPSRC))
MIDSRC := $(shell find assets -name "*.mid")
JSONSRC := $(shell find assets -name "*.json")
ASSETLISTS := $(shell find src/gen/assets -name "*.s.asset")
ASSETOBJS = $(filter-out $(ASSETLISTS),$(patsubst src/%,$(ODIR)/%,$(ASSETLISTS:s.asset=o)))
SLCSRC := $(shell find assets -name "*.slc")

BMPOBJS = $(patsubst %,$(ODIR)/%,$(BMPSRC:bmp=gtg.deflate))
MIDOBJS = $(patsubst %,$(ODIR)/%,$(MIDSRC:mid=gtm2))
JSONOBJS = $(patsubst %,$(ODIR)/%,$(JSONSRC:json=gsi))
SLCOBJS = $(patsubst %,$(ODIR)/%,$(SLCSRC:slc=bin))

CFLAGS = -t none -Osr --cpu 65c02 --codesize 500 --static-locals -I src/gt
AFLAGS = --cpu 65C02 --bin-include-dir lib --bin-include-dir $(ODIR)/assets
LFLAGS = -C gametank-2M.cfg -m $(ODIR)/out.map -vm
LLIBS = lib/gametank.lib

C_SRCS := $(shell find src -name "*.c")
COBJS = $(patsubst src/%,$(ODIR)/%,$(C_SRCS:c=o))

A_SRCS := $(shell find src -name "*.s")
AOBJS = $(filter-out $(ASSETLISTS),$(patsubst src/%,$(ODIR)/%,$(A_SRCS:s=o)))

_AUDIO_FW = audio_fw.bin.deflate
AUDIO_FW = $(patsubst %,$(ODIR)/assets/%,$(_AUDIO_FW))

-include bankMakeList #sets _BANKS
_BANKS ?= bankFF
BANKS = $(patsubst %,bin/$(TARGET).%,$(_BANKS))

bin/$(TARGET): $(BANKS)
	cat $(BANKS) > $@

$(info ASSETOBJS is $(ASSETOBJS))

$(BANKS): $(ASSETOBJS) $(AOBJS) $(COBJS) $(LLIBS) gametank-2M.cfg
	mkdir -p $(@D)
	$(LN) $(LFLAGS) $(ASSETOBJS) $(AOBJS) $(COBJS) -o bin/$(TARGET) $(LLIBS)

.PRECIOUS: $(ODIR)/assets/%.bin
$(ODIR)/assets/maps/microban.bin $(ODIR)/assets/passwords/passwords.bin: assets/maps/microban.slc
	mkdir -p $(ODIR)/assets/maps/
	node $(NODE_SCRIPTS)/sokoban/sokoban.js assets/maps/microban.slc $(ODIR)/assets/maps/microban.bin $(ODIR)/assets/maps/passwords.bin

.PRECIOUS: $(ODIR)/assets/%.gtg
$(ODIR)/assets/%.gtg: assets/%.bmp
	mkdir -p $(@D)
	OUTSPRITES=$$(node $(NODE_SCRIPTS)/converters/sprite_convert.js $< $@);\
	zopfli --deflate $$OUTSPRITES

.PRECIOUS: $(ODIR)/assets/%.gtm2
$(ODIR)/assets/%.gtm2: assets/%.mid
	mkdir -p $(@D)
	node $(NODE_SCRIPTS)/converters/midiconvert.js $< $@

.PRECIOUS: $(ODIR)/assets/%.deflate
$(ODIR)/assets/%.deflate: $(ODIR)/assets/%
	mkdir -p $(@D)
	zopfli --deflate $<

.PRECIOUS: $(ODIR)/assets/%.gsi
$(ODIR)/assets/%.gsi: assets/%.json
	mkdir -p $(@D)
	node $(NODE_SCRIPTS)/converters/sprite_metadata.js $< $@

$(ODIR)/assets/audio_fw.bin.deflate: $(ODIR)/assets/audio_fw.bin
	zopfli --deflate $<

$(ODIR)/assets/audio_fw.bin: src/gt/audio_fw.asm gametank-acp.cfg
	mkdir -p $(@D)
	$(AS) --cpu 65C02 src/gt/audio_fw.asm -o $(ODIR)/assets/audio_fw.o
	$(LN) -C gametank-acp.cfg $(ODIR)/assets/audio_fw.o -o $(ODIR)/assets/audio_fw.bin

$(ODIR)/gen/assets/%.o: src/gen/assets/%.s.asset $(BMPOBJS) $(JSONOBJS) $(AUDIO_FW) $(MIDOBJS) $(SLCOBJS)
	mkdir -p $(@D)
	$(AS) $(AFLAGS) -o $@ $<

$(ODIR)/%.si: src/%.c src/%.h
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -o $@ $<

$(ODIR)/%.si: src/%.c
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -o $@ $<

$(ODIR)/%.o: $(ODIR)/%.si
	mkdir -p $(@D)
	$(AS) $(AFLAGS) -o $@ $<

$(ODIR)/%.o: src/%.s
	mkdir -p $(@D)
	$(AS) $(AFLAGS) -o $@ $<

$(ODIR)/gt/crt0.o: src/gt/crt0.s build/assets/audio_fw.bin.deflate
	mkdir -p $(@D)
	$(AS) $(AFLAGS) -o $@ $<

gametank-2M.cfg:
	node $(NODE_SCRIPTS)/build_setup/import_assets.js

dummy%:
	@:

.PHONY: clean flash emulate import

clean:
	rm -rf $(ODIR)/*
	rm -rf bin/*

flash: $(BANKS)
	$(FLASHTOOL)/bin/GTFO -p $(PORT) bin/$(TARGET).bank*

emulate: bin/$(TARGET)
	$(EMUPATH)/build/GameTankEmulator bin/$(TARGET)

scripts/node_modules:

import: scripts/node_modules
	node $(NODE_SCRIPTS)/build_setup/import_assets.js
