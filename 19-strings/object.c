#include <stdio.h>
#include <string.h>

#include "memory.h"
#include "object.h"
#include "value.h"
#include "vm.h"

static Obj *allocateObject(int size, ObjType type)
{
  Obj *obj = reallocate(NULL, 0, size);
  obj->type = type;
  obj->next = vm.objects;
  vm.objects = obj;

  return obj;
}

static ObjString *allocateString(char *chars, int length, uint32_t hash)
{
  ObjString *objString = ALLOCATE_OBJ(ObjString, OBJ_STRING);
  objString->obj.type = OBJ_STRING;
  objString->length = length;
  objString->chars = chars;
  objString->hash = hash;

  return objString;
}

static uint32_t hashString(const char *key, int length)
{
  uint32_t hash = 2166136261u;
  for (int i = 0; i < length; i++)
  {
    hash ^= (uint8_t)key[i];
    hash *= 16777619;
  }
  return hash;
}

ObjString *copyString(const char *chars, int length)
{
  uint32_t hash = hashString(chars, length);
  char *heapChars = ALLOCATE(char, length + 1);
  memcpy(heapChars, chars, length);
  heapChars[length] = '\0';

  return allocateString(heapChars, length, hash);
}

ObjString *takeString(char *chars, int length)
{
  uint32_t hash = hashString(chars, length);
  return allocateString(chars, length, hash);
}

void printObject(Value value)
{
  switch (OBJ_TYPE(value))
  {
  case OBJ_STRING:
    printf("%s", AS_CSTRING(value));
    break;
  }
}
