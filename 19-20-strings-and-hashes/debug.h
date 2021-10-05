#ifndef clox_debug_h
#define clox_debug_h

#include "chunk.h"

void disassembleChunk(Chunk *chunk, const char *title);
int disassembleInstruction(Chunk *chunk, int offset);
int simpleInstruction(const char *name, int offset);
int constantIntruction(const char *name, Chunk *chunk, int offset);

#endif
