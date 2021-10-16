#ifndef clox_object_h
#define clox_object_h

#include <stdlib.h>
#include <string.h>

#include "chunk.h"
#include "common.h"
#include "value.h"

#define OBJ_TYPE(value) (AS_OBJ(value)->type)
#define IS_STRING(value) (isObjType(value, OBJ_STRING))
#define IS_FUNCTION(value) (isObjType(value, OBJ_FUNCTION))
#define IS_NATIVE_FUNCTION(value) (isObjType(value, OBJ_NATIVE_FUNCTION))
#define IS_CLOSURE(value) (isObjType(value, OBJ_CLOSURE))
#define AS_STRING(value) ((ObjString *)AS_OBJ(value))
#define AS_CSTRING(value) (((ObjString *)AS_OBJ(value))->chars)
#define AS_FUNCTION(value) ((ObjFunction *)AS_OBJ(value))
#define AS_NATIVE_FUNCTION(value) (((ObjNative *)AS_OBJ(value))->nativeFn)
#define AS_CLOSURE(value) ((ObjClosure *)AS_OBJ(value))

#define ALLOCATE_OBJ(cType, objType) \
  (cType *)allocateObject(sizeof(cType), objType)

typedef enum
{
  OBJ_UPVALUE,
  OBJ_CLOSURE,
  OBJ_NATIVE_FUNCTION,
  OBJ_FUNCTION,
  OBJ_STRING
} ObjType;

struct Obj
{
  ObjType type;
  struct Obj *next;
};

typedef struct
{
  Obj obj;
  int arity;
  Chunk chunk;
  ObjString *name;
  int upvalueCount;
} ObjFunction;

typedef Value (*NativeFn)(int argCount, Value *args);

typedef struct
{
  Obj obj;
  NativeFn nativeFn;
} ObjNative;

struct ObjString
{
  Obj obj;
  int length;
  char *chars;
  uint32_t hash;
};

typedef struct ObjUpvalue
{
  Obj obj;
  Value *location;
} ObjUpvalue;

typedef struct
{
  Obj obj;
  ObjFunction *function;
  ObjUpvalue **upvalues;
  int upvalueCount;
} ObjClosure;

ObjFunction *newFunction();
ObjNative *newNative(NativeFn nativeFn);
ObjClosure *newClosure(ObjFunction *function);
ObjUpvalue *newUpvalue(Value *slot);

ObjString *copyString(const char *chars, int length);
ObjString *takeString(char *chars, int length);

void printObject(Value value);

static inline bool isObjType(Value value, ObjType type)
{
  return IS_OBJ(value) && AS_OBJ(value)->type == type;
}

#endif
