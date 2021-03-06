#include <stdio.h>
#include <stdarg.h>
#include <string.h>

#include "vm.h"
#include "value.h"
#include "compiler.h"
#include "debug.h"
#include "memory.h"
#include "object.h"
#include "table.h"

VM vm;

static void resetStack()
{
  vm.stackTop = vm.stack;
  vm.frameCount = 0;
}

static void runtimeError(const char *format, ...)
{
  va_list args;
  va_start(args, format);
  vfprintf(stderr, format, args);
  va_end(args);
  fputs("\n", stderr);
  for (int i = vm.frameCount - 1; i >= 0; i--)
  {
    CallFrame *frame = &vm.frames[i];
    ObjFunction *function = frame->function;
    size_t instruction = frame->ip - function->chunk.code - 1;
    fprintf(stderr, "[line %d] in ",
            function->chunk.lines[instruction]);
    if (function->name == NULL)
    {
      fprintf(stderr, "script\n");
    }
    else
    {
      fprintf(stderr, "%s()\n", function->name->chars);
    }
  }
  resetStack();
}

void initVM()
{
  resetStack();
  vm.objects = NULL;
  initTable(&vm.strings);
  initTable(&vm.globals);
}

void freeVM()
{
  freeObjects();
  freeTable(&vm.strings);
  freeTable(&vm.globals);
}

void push(Value value)
{
  *vm.stackTop = value;
  vm.stackTop++;
}

Value pop()
{
  vm.stackTop--;
  return *vm.stackTop;
}

Value peek(int distance)
{
  return *(vm.stackTop - distance - 1);
}

static void concatenate()
{
  ObjString *b = AS_STRING(pop());
  ObjString *a = AS_STRING(pop());

  int length = a->length + b->length;

  char *chars = ALLOCATE(char, length + 1);

  memcpy(chars, a->chars, a->length);
  memcpy(chars + a->length, b->chars, b->length);

  ObjString *result = takeString(chars, length);

  push(OBJ_VAL(result));
}

bool isFalsey(Value value)
{
  return (IS_BOOL(value) && AS_BOOL(value) == false) ||
         IS_NIL(value);
}

static bool call(ObjFunction *function, int argCount)
{
  if (function->arity != argCount)
  {
    runtimeError("Expected %d arguments but got %d", function->arity, argCount);
    return false;
  }

  if (vm.frameCount == FRAMES_MAX)
  {
    runtimeError("Stack overflow");
    return false;
  }

  CallFrame *newFrame = &vm.frames[vm.frameCount++];
  newFrame->function = function;
  newFrame->ip = newFrame->function->chunk.code;
  newFrame->slots = vm.stackTop - argCount - 1;

  return true;
}
static bool callValue(Value value, int argCount)
{
  if (IS_OBJ(value) && IS_FUNCTION(value))
  {
    return call(AS_FUNCTION(value), argCount);
  }

  runtimeError("Can only call functions and classes");
  return false;
}

static InterpretResult run()
{
  CallFrame *frame = &vm.frames[vm.frameCount - 1];

#define READ_BYTE() (*frame->ip++)
#define READ_SHORT() (frame->ip += 2, (uint16_t)((frame->ip[-2] << 8) | frame->ip[-1]))
#define READ_CONSTANT() (frame->function->chunk.constants.values[READ_BYTE()])
#define READ_STRING() (AS_STRING(READ_CONSTANT()))

#define BINARY_OP(valueType, op)                    \
  do                                                \
  {                                                 \
    if (!IS_NUMBER(peek(0)) || !IS_NUMBER(peek(1))) \
    {                                               \
      runtimeError("Operands must be numbers");     \
      return INTERPRET_RUNTIME_ERROR;               \
    }                                               \
    double b = AS_NUMBER(pop());                    \
    double a = AS_NUMBER(pop());                    \
    push(valueType(a op b));                        \
  } while (false)

  for (;;)
  {
#ifdef DEBUG_TRACE_EXECUTION
    printf(" ");
    for (Value *slot = vm.stack; slot < vm.stackTop; slot++)
    {
      printf("[ ");
      printValue(*slot);
      printf(" ]");
    }
    printf("\n");
    disassembleInstruction(&frame->function->chunk, (int)(frame->ip - frame->function->chunk.code));
#endif
    uint8_t instruction;
    switch (instruction = READ_BYTE())
    {
    case OP_NEGATE:
    {
      if (!IS_NUMBER(peek(0)))
      {
        runtimeError("Operand must be a number");
        return INTERPRET_RUNTIME_ERROR;
      }

      push(NUMBER_VAL(-AS_NUMBER(pop())));
      break;
    }
    case OP_ADD:
    {
      if (IS_STRING(peek(0)) && IS_STRING(peek(1)))
      {
        concatenate();
      }
      else if (IS_NUMBER(peek(0)) && IS_NUMBER(peek(1)))
      {
        BINARY_OP(NUMBER_VAL, +);
      }
      else
      {
        runtimeError("Operands must be two numbers or two strings");
        return INTERPRET_RUNTIME_ERROR;
      }

      break;
    }
    case OP_SUBTRACT:
      BINARY_OP(NUMBER_VAL, -);
      break;
    case OP_MULTIPLY:
      BINARY_OP(NUMBER_VAL, *);
      break;
    case OP_DIVIDE:
      BINARY_OP(NUMBER_VAL, /);
      break;
    case OP_NOT:
      push(BOOL_VAL(isFalsey(pop())));
      break;
    case OP_EQUAL:
    {
      Value b = pop();
      Value a = pop();
      push(BOOL_VAL(valuesEqual(a, b)));
      break;
    }
    case OP_GREATER:
      BINARY_OP(BOOL_VAL, >);
      break;
    case OP_LESS:
      BINARY_OP(BOOL_VAL, <);
      break;
    case OP_CONSTANT:
    {
      Value constant = READ_CONSTANT();
      push(constant);
      break;
    }
    case OP_DEFINE_GLOBAL:
    {
      ObjString *constant = READ_STRING();
      tableSet(&vm.globals, constant, peek(0));
      pop();
      break;
    }
    case OP_SET_GLOBAL:
    {
      ObjString *constant = READ_STRING();
      if (tableSet(&vm.globals, constant, peek(0)))
      {
        tableDelete(&vm.globals, constant);
        runtimeError("Cannot set undeclared variable %s", constant->chars);
        return INTERPRET_RUNTIME_ERROR;
      }
      break;
    }
    case OP_GET_GLOBAL:
    {
      ObjString *constant = READ_STRING();
      Value value;
      if (!tableGet(&vm.globals, constant, &value))
      {
        runtimeError("Undefined variable %s", constant->chars);
        return INTERPRET_RUNTIME_ERROR;
      }
      push(value);
      break;
    }
    case OP_GET_LOCAL:
    {
      uint8_t slot = READ_BYTE();
      push(frame->slots[slot]);
      break;
    }
    case OP_SET_LOCAL:
    {
      uint8_t slot = READ_BYTE();
      frame->slots[slot] = peek(0);
      break;
    }
    case OP_POP:
      pop();
      break;
    case OP_FALSE:
    {
      push(BOOL_VAL(false));
      break;
    }
    case OP_TRUE:
    {
      push(BOOL_VAL(true));
      break;
    }
    case OP_NIL:
    {
      push(NIL_VAL);
      break;
    }
    case OP_PRINT:
    {
      printf("\n");
      printValue(pop());
      printf("\n\n");
      break;
    }
    case OP_RETURN:
    {
      Value result = pop();
      vm.frameCount--;

      if (vm.frameCount == 0)
      {
        pop();
        return INTERPRET_OK;
      }

      vm.stackTop = frame->slots;
      push(result);

      frame = &vm.frames[vm.frameCount - 1];
      break;
    }
    case OP_JUMP_IF_FALSE:
    {
      uint16_t offset = READ_SHORT();

      if (isFalsey(peek(0)))
        frame->ip += offset;
      break;
    }
    case OP_JUMP:
    {
      uint16_t offset = READ_SHORT();
      frame->ip += offset;
      break;
    }
    case OP_LOOP:
    {
      uint16_t offset = READ_SHORT();
      frame->ip -= offset;
      break;
    }
    case OP_CALL:
    {
      uint8_t argCount = READ_BYTE();
      if (!callValue(peek(argCount), argCount))
      {
        return INTERPRET_RUNTIME_ERROR;
      }
      frame = &vm.frames[vm.frameCount - 1];
      break;
    }
    }
  }
#undef READ_BYTE
#undef READ_SHORT
#undef READ_CONSTANT
#undef READ_STRING
#undef BINARY_OP
}

InterpretResult interpret(const char *source)
{
  ObjFunction *function = compile(source);

  if (!function)
    return INTERPRET_COMPILE_ERROR;

  push(OBJ_VAL(function));
  call(function, 0);

  InterpretResult result = run();
  return result;
}
