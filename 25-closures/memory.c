#include <stdlib.h>

#include "memory.h"
#include "vm.h"

void *reallocate(void *pointer, size_t oldSize, size_t newSize)
{
  if (newSize == 0)
  {
    free(pointer);
    return NULL;
  }

  void *result = realloc(pointer, newSize);

  if (result == NULL)
    exit(1);

  return result;
}

static void freeObject(Obj *obj)
{
  switch (obj->type)
  {
  case OBJ_STRING:
  {
    ObjString *string = (ObjString *)obj;
    FREE_ARRAY(char, string->chars, string->length + 1);
    FREE(ObjString, obj);
    break;
  }
  case OBJ_FUNCTION:
  {
    ObjFunction *function = (ObjFunction *)obj;
    freeChunk(&function->chunk);
    FREE(ObjFunction, function);
    break;
  }
  case OBJ_NATIVE_FUNCTION:
  {
    FREE(ObjNative, obj);
    break;
  }
  case OBJ_CLOSURE:
    FREE(ObjClosure, obj)
    break;
  }
}

void freeObjects()
{
  Obj *currentObject = vm.objects;

  while (currentObject != NULL)
  {
    Obj *nextObject = currentObject->next;
    freeObject(currentObject);
    currentObject = nextObject;
  }
}
