#ifndef clox_memory_h
#define clox_memory_h

#include "common.h"
#include "object.h"
#include "object.h"
#include "table.h"

#define GROW_CAPACITY(capacity) \
  ((capacity < 8) ? 8 : capacity * 2)

#define GROW_ARRAY(type, pointer, oldCount, newCount) \
  (type *)reallocate(pointer, sizeof(type) * (oldCount), sizeof(type) * (newCount))

#define FREE_ARRAY(type, pointer, oldCount) \
  reallocate(pointer, sizeof(type) * (oldCount), 0);

#define FREE(type, pointer) reallocate(pointer, sizeof(type), 0);

#define ALLOCATE(type, length) \
  (type *)reallocate(NULL, 0, sizeof(type) * (length))

void *reallocate(void *pointer, size_t oldSize, size_t newSize);
void markValue(Value value);
void markObject(Obj *obj);
void markTable(Table *table);
void freeObjects();
void collectGarbage();

#endif
