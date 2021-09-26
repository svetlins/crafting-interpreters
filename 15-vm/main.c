#include "common.h"
#include "chunk.h"
#include "debug.h"
#include "vm.h"

int main(int argc, char *argv[])
{
  initVM();
  Chunk chunk;

  initChunk(&chunk);

  // int constant = addConstant(&chunk, 42);
  // writeChunk(&chunk, OP_CONSTANT, 123);
  // writeChunk(&chunk, constant, 123);
  // writeChunk(&chunk, OP_NEGATE, 123);

  int a = addConstant(&chunk, 1.2);
  int b = addConstant(&chunk, 3.4);
  int c = addConstant(&chunk, 5.6);
  writeChunk(&chunk, OP_CONSTANT, 123);
  writeChunk(&chunk, a, 123);
  writeChunk(&chunk, OP_CONSTANT, 123);
  writeChunk(&chunk, b, 123);
  writeChunk(&chunk, OP_ADD, 123);
  writeChunk(&chunk, OP_CONSTANT, 123);
  writeChunk(&chunk, c, 123);
  writeChunk(&chunk, OP_DIVIDE, 123);
  writeChunk(&chunk, OP_NEGATE, 123);

  writeChunk(&chunk, OP_RETURN, 124);
  // disassembleChunk(&chunk, "test chunk");
  interpret(&chunk);
  freeVM();
  freeChunk(&chunk);

  return 0;
}
