/*
 * recomp_main.c - mslugx_recomp, the generator: reads the ROM files from
 * the build tree and writes the recompiled C there.
 */
#include <neogeorecomp/recomp.h>
#include "game.h"

int main(int argc, char **argv) { return ng_recomp_main(argc, argv, &k_mslugx); }
