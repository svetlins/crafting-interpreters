#include <stdio.h>
#include <string.h>

#include "memory.h"
#include "object.h"
#include "value.h"
#include "vm.h"
#include "table.h"

static Obj *allocateObject(int size, ObjType type)
{
  Obj *obj = reallocate(NULL, 0, size);
  obj->type = type;
  obj->next = vm.objects;
  printf("NEXT (ALLOC) %p -> %p\n\n", obj, obj->next);
  obj->isMarked = false;
  vm.objects = obj;

#ifdef DEBUG_LOG_GC
  printf("%p allocate %d for %d\n", (void *)obj, size, type);
#endif

  printf("%p %p\n", obj, obj->next);

  return obj;
}

static ObjString *allocateString(char *chars, int length, uint32_t hash)
{
  ObjString *objString = ALLOCATE_OBJ(ObjString, OBJ_STRING);
  objString->obj.type = OBJ_STRING;
  objString->length = length;
  objString->chars = chars;
  objString->hash = hash;

  push(OBJ_VAL(objString));
  tableSet(&vm.strings, objString, NIL_VAL);
  pop();

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

static void printFunction(ObjFunction *function)
{
  if (function->name == NULL)
  {
    printf("<script>");
    return;
  }
  printf("<fn %s>", function->name->chars);
}

ObjFunction *newFunction()
{
  ObjFunction *function = ALLOCATE_OBJ(ObjFunction, OBJ_FUNCTION);
  function->arity = 0;
  function->name = NULL;
  function->upvalueCount = 0;
  initChunk(&function->chunk);

  return function;
}

ObjNative *newNative(NativeFn nativeFn)
{
  ObjNative *objNativeFn = ALLOCATE_OBJ(ObjNative, OBJ_NATIVE_FUNCTION);
  objNativeFn->nativeFn = nativeFn;

  return objNativeFn;
}

ObjClosure *newClosure(ObjFunction *function)
{
  ObjUpvalue **upvalues = ALLOCATE(ObjUpvalue *, function->upvalueCount);

  for (int i = 0; i < function->upvalueCount; i++)
  {
    upvalues[i] = NULL;
  }

  ObjClosure *closure = ALLOCATE_OBJ(ObjClosure, OBJ_CLOSURE);
  closure->function = function;
  closure->upvalues = upvalues;
  closure->upvalueCount = function->upvalueCount;

  return closure;
}

ObjUpvalue *newUpvalue(Value *slot)
{
  ObjUpvalue *upvalue = ALLOCATE_OBJ(ObjUpvalue, OBJ_UPVALUE);
  upvalue->location = slot;
  upvalue->next = NULL;
  upvalue->closed = NIL_VAL;
  return upvalue;
}

ObjString *copyString(const char *chars, int length)
{
  uint32_t hash = hashString(chars, length);

  ObjString *interned = tableFindString(&vm.strings, chars, length, hash);

  if (interned != NULL)
    return interned;

  char *heapChars = ALLOCATE(char, length + 1);
  memcpy(heapChars, chars, length);
  heapChars[length] = '\0';

  return allocateString(heapChars, length, hash);
}

ObjString *takeString(char *chars, int length)
{
  uint32_t hash = hashString(chars, length);

  ObjString *interned = tableFindString(&vm.strings, chars, length, hash);

  if (interned != NULL)
  {
    FREE_ARRAY(char, chars, length + 1);
    return interned;
  }

  return allocateString(chars, length, hash);
}

void printObject(Value value)
{
  switch (OBJ_TYPE(value))
  {
  case OBJ_STRING:
    printf("%s", AS_CSTRING(value));
    break;
  case OBJ_FUNCTION:
    printFunction(AS_FUNCTION(value));
    break;
  case OBJ_NATIVE_FUNCTION:
    printf("<native fn>");
    break;
  case OBJ_CLOSURE:
    printFunction(AS_CLOSURE(value)->function);
    break;
  case OBJ_UPVALUE:
    printf("upvalue");
    break;
  }
}
