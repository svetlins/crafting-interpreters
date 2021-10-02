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

  return obj;
}

ObjString *allocateString(char *chars, int length)
{
  ObjString *objString = ALLOCATE_OBJ(ObjString, OBJ_STRING);
  objString->obj.type = OBJ_STRING;
  objString->length = length;
  objString->chars = chars;

  return objString;
}

ObjString *copyString(const char *chars, int length)
{
  char *heapChars = ALLOCATE(char, length + 1);
  memcpy(heapChars, chars, length);
  heapChars[length] = '\0';

  return allocateString(heapChars, length);
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
