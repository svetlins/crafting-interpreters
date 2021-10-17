#include <stdlib.h>

#include "memory.h"
#include "vm.h"
#include "compiler.h"
#include "object.h"

#ifdef DEBUG_LOG_GC
#include <stdio.h>
#include "debug.h"
#endif

void *reallocate(void *pointer, size_t oldSize, size_t newSize)
{
  if (newSize > oldSize)
  {
#ifdef DEBUG_STRESS_GC
    collectGarbage();
#endif
  }

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
#ifdef DEBUG_LOG_GC
  printf("%p free type %d\n", (void *)obj, obj->type);
#endif

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
  {
    ObjClosure *closure = (ObjClosure *)obj;
    FREE_ARRAY(ObjUpvalue *, closure->upvalues, closure->upvalueCount);
    FREE(ObjClosure, obj);
    break;
  }
  case OBJ_UPVALUE:
    FREE(ObjUpvalue, obj);
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

  free(vm.grayStack);
}

void markObject(Obj *obj)
{
  if (obj == NULL)
    return;

  if (obj->isMarked)
    return;

#ifdef DEBUG_LOG_GC
  printf("%p mark ", (void *)obj);
  printValue(OBJ_VAL(obj));
  printf("\n");
#endif

  obj->isMarked = true;

  if (vm.grayCapacity < vm.grayCount + 1)
  {
    vm.grayCapacity = GROW_CAPACITY(vm.grayCapacity);
    vm.grayStack = (Obj **)realloc(vm.grayStack, vm.grayCapacity);

    if (vm.grayStack == NULL)
      exit(1);
  }

  vm.grayStack[vm.grayCount++] = obj;
}

void markTable(Table *table)
{
  for (int i = 0; i < table->capacity; i++)
  {
    Entry *entry = &table->entries[i];
    markObject((Obj *)entry->key);
    markValue(entry->value);
  }
}

void markValue(Value value)
{
  if (IS_OBJ(value))
  {
    markObject(AS_OBJ(value));
  }
}

static void markRoots()
{
  for (Value *slot = vm.stack; slot < vm.stackTop; slot++)
  {
    markValue(*slot);
  }

  for (int i = 0; i < vm.frameCount; i++)
  {
    markObject((Obj *)vm.frames[i].closure);
  }

  for (ObjUpvalue *upvalue = vm.openUpvalues;
       upvalue != NULL;
       upvalue = upvalue->next)
  {
    markObject((Obj *)upvalue);
  }

  markTable(&vm.globals);
  markCompilerRoots();
}

static void markArray(ValueArray *array)
{
  for (int i = 0; i < array->count; i++)
  {
    markValue(array->values[i]);
  }
}

static void blackenObject(Obj *obj)
{
#ifdef DEBUG_LOG_GC
  printf("%p blacken ", (void *)obj);
  printValue(OBJ_VAL(obj));
  printf("\n");
#endif

  switch (obj->type)
  {
  case OBJ_NATIVE_FUNCTION:
    break;
  case OBJ_STRING:
    break;
  case OBJ_UPVALUE:
    markValue(((ObjUpvalue *)obj)->closed);
    break;
  case OBJ_FUNCTION:
  {
    ObjFunction *function = (ObjFunction *)obj;
    markObject((Obj *)function->name);
    markArray(&function->chunk.constants);
    break;
  }
  case OBJ_CLOSURE:
  {
    ObjClosure *closure = (ObjClosure *)obj;
    markObject((Obj *)closure->function);
    for (int i = 0; i < closure->upvalueCount; i++)
    {
      markObject((Obj *)closure->upvalues[i]);
    }
    break;
  }
  default:
    break;
  }
}

static void traceReferences()
{
  while (vm.grayCount > 0)
  {
    Obj *obj = vm.grayStack[--vm.grayCount];
    blackenObject(obj);
  }
}

static void sweep()
{
  Obj *previous = NULL;
  Obj *object = vm.objects;

  while (object != NULL)
  {
    if (object->isMarked)
    {
      object->isMarked = false;
      previous = object;

      object = object->next;
    }
    else
    {
      Obj *unreached = object;
      object = object->next;

      if (previous != NULL)
      {
        previous->next = object;
        printf("NEXT (GC) %p -> %p\n\n", previous, previous->next);
      }
      else
      {
        vm.objects = object;
      }

      freeObject(unreached);
    }
  }
}

void collectGarbage()
{
#ifdef DEBUG_LOG_GC
  printf("-- gc begin\n");
#endif

  markRoots();
  traceReferences();
  tableRemoveWhite(&vm.strings);
  sweep();

#ifdef DEBUG_LOG_GC
  printf("-- gc end\n");
#endif
}
