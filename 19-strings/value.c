#include <stdio.h>

#include "memory.h"
#include "value.h"

void initValueArray(ValueArray *array)
{
  array->capacity = 0;
  array->count = 0;
  array->values = NULL;
}
void writeValueArray(ValueArray *array, Value value)
{
  if (array->capacity < array->count + 1)
  {
    int oldCapacity = array->capacity;
    array->capacity = GROW_CAPACITY(oldCapacity);
    array->values = GROW_ARRAY(Value, array->values, oldCapacity, array->capacity);
  }

  array->values[array->count] = value;
  array->count++;
}

void freeValueArray(ValueArray *array)
{
  FREE_ARRAY(Value, array->values, array->capacity);
  initValueArray(array);
}

bool valuesEqual(Value a, Value b)
{
  if (a.type != b.type)
    return false;

  switch (a.type)
  {
  case VAL_NIL:
    return true;
  case VAL_NUMBER:
    return AS_NUMBER(a) == AS_NUMBER(b);
  case VAL_BOOL:
    return AS_BOOL(a) == AS_BOOL(b);
  default:
    return false;
  }
}

void printValue(Value value)
{
  if (value.type == VAL_NUMBER)
    printf("%g", AS_NUMBER(value));
  else if (value.type == VAL_BOOL)
    printf(AS_BOOL(value) ? "true" : "false");
  else if (value.type == VAL_NIL)
    printf("nil");
}
