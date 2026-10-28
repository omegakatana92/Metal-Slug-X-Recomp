/*
 * game.c - the Metal Slug X (MAME set "mslugx", NGM-250) ROM layout.
 *
 * Plain, unencrypted MVS/AES cartridge: no NEO-SMA, no NEO-CMC, no
 * protection latch.  The layout below is transcribed from MAME's
 * neogeo.cpp ROM_START(mslugx) and verified against the supplied dump:
 *
 *   250-p1.p1    1 MB   fixed bank (contains "NEO-GEO" at $100)
 *   250-p2.ep1   4 MB   banked image, first MB = bank 0
 *   250-c1..c6   6 x 8 MB, byte-interleaved to 48 MB of sprites
 *   250-s1.s1  128 KB   fixed layer
 *   250-m1.m1  128 KB   Z80 sound driver
 *   250-v1..v3  4+4+2 MB  ADPCM-A samples
 *
 * MAME loads P1 at maincpu offset 0 and P2 at 0x100000 with
 * ROM_LOAD16_WORD_SWAP, i.e. both files are byte-swapped per 16-bit word
 * and no half reordering is needed (unlike the 2 MB single-file sets such
 * as mslug, which MAME loads with ROM_CONTINUE).
 *
 * Program banking is the standard NEO-ZMC scheme: the value written to
 * $2FFFF0 selects a 1 MB bank, and bank N is P2[N * 1 MB].  The runtime's
 * default (bank_map == NULL, bank_write_addr == 0) implements exactly that,
 * so this file only has to describe the region.
 */
#include "game.h"

const ng_game_t k_mslugx = {
    .name = "mslugx",
    .title = "Metal Slug X - Super Vehicle-001",
    .prom_size = 0x500000,                  /* 1 MB fixed + 4 MB banked */
    .prom = {
        {"250-p1.p1",  0x000000, 0x000000, 0x100000, 1},  /* fixed bank */
        {"250-p2.ep1", 0x000000, 0x100000, 0x400000, 1},  /* banked image */
    },
    .crom_size = 0x3000000,                 /* 48 MB after pairing */
    .crom_pairs = {
        {"250-c1.c1", "250-c2.c2"},
        {"250-c3.c3", "250-c4.c4"},
        {"250-c5.c5", "250-c6.c6"},
    },
    .srom = "250-s1.s1",
    .m1 = "250-m1.m1",
    .vrom = {"250-v1.v1", "250-v2.v2", "250-v3.v3"},
    .fix_bank_type = NG_FIX_BANK_NONE,      /* plain 128 KB S ROM */
    .bank_map = 0,                          /* standard 1 MB banking */
    .bank_write_addr = 0,                   /* $2FFFF0-$2FFFFF */
    /* NEO-MVS PROGEOP: the ALTERA on this cartridge answers at
     * $2FFFE0-$2FFFEF.  The game's boot self-test reads a bit table at
     * $0DEDD2 (fixed bank) and, in its verify pass, uses the work-RAM word
     * at $10F00A as the selector.  Both addresses are part of this cart's
     * program, so they live here rather than in the generic bus. */
    .prot_type = NG_PROT_TYPE_BITSTREAM,
    .prot_table_addr = 0x0DEDD2,
    .prot_select_addr = 0x10F00A,
    .prot_read_addr = 0,
    .prot_value = 0,
};
