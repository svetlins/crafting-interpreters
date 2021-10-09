#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "common.h"
#include "compiler.h"
#include "scanner.h"
#include "chunk.h"
#include "debug.h"

typedef struct
{
  Token current;
  Token previous;
  bool hadError;
  bool panicMode;
} Parser;

typedef enum
{
  PREC_NONE,
  PREC_ASSIGNMENT,
  PREC_OR,
  PREC_AND,
  PREC_EQUALITY,
  PREC_COMPARISON,
  PREC_TERM,
  PREC_FACTOR,
  PREC_UNARY,
  PREC_CALL,
  PREC_PRIMARY
} Precedence;

typedef void (*ParseFn)(bool canAssign);

typedef struct
{
  ParseFn prefix;
  ParseFn infix;
  Precedence precedence;
} ParseRule;

typedef struct
{
  Token name;
  int depth;
} Local;

typedef struct
{
  Local locals[UINT8_COUNT];
  int localCount;
  int scopeDepth;
} Compiler;

Parser parser;
Compiler *current = NULL;
Chunk *compilingChunk;

static Chunk *currentChunk()
{
  return compilingChunk;
}

static void errorAt(Token *token, const char *message)
{
  if (parser.panicMode)
    return;

  parser.panicMode = true;
  fprintf(stderr, "[line %d] Error", token->line);

  if (token->type == TOKEN_EOF)
  {
    fprintf(stderr, " at end");
  }
  else if (token->type == TOKEN_ERROR)
  {
  }
  else
  {
    fprintf(stderr, " at %.*s", token->length, token->start);
  }

  fprintf(stderr, ": %s\n", message);
  parser.hadError = true;
}

static void error(const char *message)
{
  errorAt(&parser.previous, message);
}

static void errorAtCurrent(const char *message)
{
  errorAt(&parser.current, message);
}

static void advance()
{
  parser.previous = parser.current;

  for (;;)
  {
    parser.current = scanToken();
    if (parser.current.type != TOKEN_ERROR)
      break;

    errorAtCurrent(parser.current.start);
  }
}

static void consume(TokenType type, const char *message)
{
  if (parser.current.type == type)
  {
    advance();
    return;
  }

  error(message);
}

static bool check(TokenType type)
{
  return parser.current.type == type;
}

static bool match(TokenType type)
{
  if (check(type))
  {
    advance();
    return true;
  }
  else
  {
    return false;
  }
}

static void emitByte(uint8_t byte)
{
  writeChunk(currentChunk(), byte, parser.previous.line);
}

static void emitBytes(uint8_t byte1, uint8_t byte2)
{
  emitByte(byte1);
  emitByte(byte2);
}

static void emitReturn()
{
  emitByte(OP_RETURN);
}

static uint8_t makeConstant(Value value)
{
  int constant = addConstant(currentChunk(), value);

  if (constant > UINT8_MAX)
  {
    error("Too many constants in one chunk");
    return 0;
  }

  return (uint8_t)constant;
}

static void emitConstant(Value value)
{
  emitBytes(OP_CONSTANT, makeConstant(value));
}

static void initCompiler(Compiler *compiler)
{
  compiler->scopeDepth = 0;
  compiler->localCount = 0;
  current = compiler;
}

static void endCompiler()
{
  emitReturn();

#ifdef DEBUG_PRINT_CODE
  if (!parser.hadError)
  {
    disassembleChunk(currentChunk(), "code");
  }
#endif
}

static void expression();
static void statement();
static void declaration();
static ParseRule *getRule(TokenType type);
static void parsePrecedence(Precedence precedence);
static uint8_t parseVariable(const char *message);
static uint8_t identifierConstant(Token *token);
static void defineVariable(uint8_t global);
static bool identifiersEqual(Token *a, Token *b);
static int emitJump(uint8_t jumpInstruction);
static void patchJump(int jump);
static void string(bool canAssign)
{
  emitConstant(OBJ_VAL(copyString(parser.previous.start + 1, parser.previous.length - 2)));
}

static int resolveLocal(Compiler *compiler, Token *name)
{
  for (int i = compiler->localCount - 1; i >= 0; i--)
  {
    Local *local = &compiler->locals[i];
    if (identifiersEqual(&local->name, name))
    {
      if (local->depth == -1)
        errorAt(name, "Can't access variable in its initializer");

      return i;
    }
  }

  return -1;
}

static void namedVariable(Token *name, bool canAssign)
{
  uint8_t getOp, setOp;
  int arg = resolveLocal(current, name);

  if (arg != -1)
  {
    getOp = OP_GET_LOCAL;
    setOp = OP_SET_LOCAL;
  }
  else
  {
    getOp = OP_GET_GLOBAL;
    setOp = OP_SET_GLOBAL;
    arg = identifierConstant(name);
  }

  //  uint8_t arg = identifierConstant(name);

  if (canAssign && match(TOKEN_EQUAL))
  {
    expression();
    emitBytes(setOp, arg);
  }
  else
  {
    emitBytes(getOp, arg);
  }
}

static void variable(bool canAssign)
{
  namedVariable(&parser.previous, canAssign);
}

static void binary(bool canAssign)
{
  TokenType operatorType = parser.previous.type;
  ParseRule *rule = getRule(operatorType);
  parsePrecedence((Precedence)(rule->precedence + 1));

  switch (operatorType)
  {
  case TOKEN_PLUS:
    emitByte(OP_ADD);
    break;
  case TOKEN_MINUS:
    emitByte(OP_SUBTRACT);
    break;
  case TOKEN_STAR:
    emitByte(OP_MULTIPLY);
    break;
  case TOKEN_SLASH:
    emitByte(OP_DIVIDE);
    break;
  case TOKEN_EQUAL_EQUAL:
    emitByte(OP_EQUAL);
    break;
  case TOKEN_BANG_EQUAL:
    emitByte(OP_EQUAL);
    emitByte(OP_NOT);
    break;
  case TOKEN_GREATER:
    emitByte(OP_GREATER);
    break;
  case TOKEN_GREATER_EQUAL:
    emitByte(OP_LESS);
    emitByte(OP_NOT);
    break;
  case TOKEN_LESS:
    emitByte(OP_LESS);
    break;
  case TOKEN_LESS_EQUAL:
    emitByte(OP_GREATER);
    emitByte(OP_NOT);
    break;
  default:
    return;
  }
}

static void beginScope()
{
  current->scopeDepth++;
}

static void endScope()
{
  current->scopeDepth--;

  while (current->localCount > 0 && current->locals[current->localCount - 1].depth > current->scopeDepth)
  {
    emitByte(OP_POP);
    current->localCount--;
  }
}

static void expression()
{
  parsePrecedence(PREC_ASSIGNMENT);
}

static void andExpression(bool canAssign)
{
  int jump = emitJump(OP_JUMP_IF_FALSE);
  emitByte(OP_POP);
  parsePrecedence(PREC_AND);
  patchJump(jump);
}

static void orExpression(bool canAssign)
{
  int elseJump = emitJump(OP_JUMP_IF_FALSE);
  int thenJump = emitJump(OP_JUMP);

  patchJump(elseJump);
  emitByte(OP_POP);

  parsePrecedence(PREC_OR);

  patchJump(thenJump);
}

static void block()
{
  while (!check(TOKEN_RIGHT_BRACE) && !check(TOKEN_EOF))
  {
    declaration();
  }

  consume(TOKEN_RIGHT_BRACE, "Expected } at end of block");
}

static void variableDeclaration()
{
  uint8_t variable = parseVariable("Expected variable name");

  if (match(TOKEN_EQUAL))
  {
    expression();
  }
  else
  {
    emitByte(OP_NIL);
  }

  consume(TOKEN_SEMICOLON, "Expected ; after variable declaration");

  defineVariable(variable);
}

static void expressionStatement()
{
  expression();
  consume(TOKEN_SEMICOLON, "Expected ; after expression.");
  emitByte(OP_POP);
}

static void synchronize()
{
  parser.panicMode = false;

  while (parser.current.type != TOKEN_EOF)
  {
    if (parser.previous.type == TOKEN_SEMICOLON)
      return;
    switch (parser.current.type)
    {
    case TOKEN_CLASS:
    case TOKEN_FUN:
    case TOKEN_VAR:
    case TOKEN_FOR:
    case TOKEN_IF:
    case TOKEN_WHILE:
    case TOKEN_PRINT:
    case TOKEN_RETURN:
      return;
    default:
      break;
    }
    advance();
  }
}

static void declaration()
{
  if (match(TOKEN_VAR))
  {
    variableDeclaration();
  }
  else
  {
    statement();
  }

  if (parser.panicMode)
    synchronize();
}

static void printStatement()
{
  expression();
  consume(TOKEN_SEMICOLON, "Expected ; after value.");
  emitByte(OP_PRINT);
}

static int emitJump(uint8_t jumpInstruction)
{
  emitByte(jumpInstruction);
  emitByte(0xff);
  emitByte(0xff);
  return currentChunk()->count - 2;
}

static void patchJump(int offset)
{
  // -2 to adjust for the bytecode for the jump offset itself.
  int jump = currentChunk()->count - offset - 2;

  if (jump > UINT16_MAX)
  {
    error("Too much code to jump over.");
  }

  currentChunk()->code[offset] = (jump >> 8) & 0xff;
  currentChunk()->code[offset + 1] = jump & 0xff;
}

static void ifStatement()
{
  consume(TOKEN_LEFT_PAREN, "Expected ( before if condition");
  expression();
  consume(TOKEN_RIGHT_PAREN, "Expected ) after if condition");
  int thenJump = emitJump(OP_JUMP_IF_FALSE);
  emitByte(OP_POP);
  statement(); // then
  int elseJump = emitJump(OP_JUMP);
  patchJump(thenJump);

  emitByte(OP_POP);
  if (match(TOKEN_ELSE))
    statement(); // else

  patchJump(elseJump);
}

static void statement()
{
  if (match(TOKEN_PRINT))
  {
    printStatement();
  }
  else if (match(TOKEN_LEFT_BRACE))
  {
    beginScope();
    block();
    endScope();
  }
  else if (match(TOKEN_IF))
  {
    ifStatement();
  }
  else
  {
    expressionStatement();
  }
}

static void grouping(bool canAssign)
{
  expression();
  consume(TOKEN_RIGHT_PAREN, "Expected ) after expression");
}

static void number(bool canAssign)
{
  double value = strtod(parser.previous.start, NULL);
  emitConstant(NUMBER_VAL(value));
}

static void literal(bool canAssign)
{
  switch (parser.previous.type)
  {
  case TOKEN_FALSE:
    emitByte(OP_FALSE);
    break;
  case TOKEN_TRUE:
    emitByte(OP_TRUE);
    break;
  case TOKEN_NIL:
    emitByte(OP_NIL);
    break;

  default:
    return;
  }
}

static void unary(bool canAssign)
{
  TokenType operatorType = parser.previous.type;
  parsePrecedence(PREC_UNARY);
  switch (operatorType)
  {
  case TOKEN_MINUS:
    emitByte(OP_NEGATE);
    break;
  case TOKEN_BANG:
    emitByte(OP_NOT);
    break;
  default: // improv
    errorAt(&parser.previous, "Expected valid unary operator");
  }
}

ParseRule rules[] = {
    [TOKEN_LEFT_PAREN] = {grouping, NULL, PREC_NONE},
    [TOKEN_RIGHT_PAREN] = {NULL, NULL, PREC_NONE},
    [TOKEN_LEFT_BRACE] = {NULL, NULL, PREC_NONE},
    [TOKEN_RIGHT_BRACE] = {NULL, NULL, PREC_NONE},
    [TOKEN_COMMA] = {NULL, NULL, PREC_NONE},
    [TOKEN_DOT] = {NULL, NULL, PREC_NONE},
    [TOKEN_MINUS] = {unary, binary, PREC_TERM},
    [TOKEN_PLUS] = {NULL, binary, PREC_TERM},
    [TOKEN_SEMICOLON] = {NULL, NULL, PREC_NONE},
    [TOKEN_SLASH] = {NULL, binary, PREC_FACTOR},
    [TOKEN_STAR] = {NULL, binary, PREC_FACTOR},
    [TOKEN_BANG] = {unary, NULL, PREC_NONE},
    [TOKEN_EQUAL] = {NULL, NULL, PREC_NONE},
    [TOKEN_BANG_EQUAL] = {NULL, binary, PREC_EQUALITY},
    [TOKEN_EQUAL_EQUAL] = {NULL, binary, PREC_EQUALITY},
    [TOKEN_GREATER] = {NULL, binary, PREC_COMPARISON},
    [TOKEN_GREATER_EQUAL] = {NULL, binary, PREC_COMPARISON},
    [TOKEN_LESS] = {NULL, binary, PREC_COMPARISON},
    [TOKEN_LESS_EQUAL] = {NULL, binary, PREC_COMPARISON},
    [TOKEN_IDENTIFIER] = {variable, NULL, PREC_NONE}, // PREC_PRIMARY????
    [TOKEN_STRING] = {string, NULL, PREC_NONE},
    [TOKEN_NUMBER] = {number, NULL, PREC_NONE}, // PREC_PRIMARY?
    [TOKEN_AND] = {NULL, andExpression, PREC_AND},
    [TOKEN_CLASS] = {NULL, NULL, PREC_NONE},
    [TOKEN_ELSE] = {NULL, NULL, PREC_NONE},
    [TOKEN_FALSE] = {literal, NULL, PREC_NONE},
    [TOKEN_FOR] = {NULL, NULL, PREC_NONE},
    [TOKEN_FUN] = {NULL, NULL, PREC_NONE},
    [TOKEN_IF] = {NULL, NULL, PREC_NONE},
    [TOKEN_NIL] = {literal, NULL, PREC_NONE},
    [TOKEN_OR] = {NULL, orExpression, PREC_OR},
    [TOKEN_PRINT] = {NULL, NULL, PREC_NONE},
    [TOKEN_RETURN] = {NULL, NULL, PREC_NONE},
    [TOKEN_SUPER] = {NULL, NULL, PREC_NONE},
    [TOKEN_THIS] = {NULL, NULL, PREC_NONE},
    [TOKEN_TRUE] = {literal, NULL, PREC_NONE},
    [TOKEN_VAR] = {NULL, NULL, PREC_NONE},
    [TOKEN_WHILE] = {NULL, NULL, PREC_NONE},
    [TOKEN_ERROR] = {NULL, NULL, PREC_NONE},
    [TOKEN_EOF] = {NULL, NULL, PREC_NONE},
};

static void parsePrecedence(Precedence precedence)
{
  advance();
  ParseFn prefixRule = getRule(parser.previous.type)->prefix;
  if (prefixRule == NULL)
  {
    error("Expected expression");
    return;
  }

  bool canAssign = precedence <= PREC_ASSIGNMENT;
  prefixRule(canAssign);

  while (precedence <= getRule(parser.current.type)->precedence)
  {
    advance();
    ParseFn infixRule = getRule(parser.previous.type)->infix;
    infixRule(canAssign);
  }

  if (canAssign && match(TOKEN_EQUAL))
  {
    error("Invalid assignment target");
  }
}

static uint8_t identifierConstant(Token *token)
{
  return makeConstant(OBJ_VAL(copyString(token->start, token->length)));
}

static void addLocal(Token name)
{
  if (current->localCount > UINT8_COUNT)
  {
    error("Too many local variables in block");
    return;
  }

  Local *local = &current->locals[current->localCount++];
  local->name = name;
  local->depth = -1;
}

static bool identifiersEqual(Token *a, Token *b)
{
  if (a->length != b->length)
    return false;

  return memcmp(a->start, b->start, a->length) == 0;
}

static void declareVariable()
{
  if (current->scopeDepth == 0)
    return;

  Token *name = &parser.previous;

  for (int i = current->localCount - 1; i >= 0; i--)
  {
    Local *local = &current->locals[i];
    if (local->depth != -1 && local->depth < current->scopeDepth)
      break;

    if (identifiersEqual(name, &local->name))
      errorAt(name, "Redeclaring local in the same scope is verboten");
  }

  addLocal(*name);
}

static uint8_t parseVariable(const char *message)
{
  consume(TOKEN_IDENTIFIER, message);

  declareVariable();
  if (current->scopeDepth > 0)
    return 0;

  return identifierConstant(&parser.previous);
}

static void markInitialized()
{
  current->locals[current->localCount - 1].depth = current->scopeDepth;
}
static void defineVariable(uint8_t global)
{
  if (current->scopeDepth > 0)
  {
    markInitialized();
    return;
  }

  emitBytes(OP_DEFINE_GLOBAL, global);
}

static ParseRule *getRule(TokenType type)
{
  return &rules[type];
}

bool compile(const char *source, Chunk *chunk)
{
  initScanner(source);

  Compiler compiler;
  initCompiler(&compiler);

  compilingChunk = chunk;
  parser.hadError = false;
  parser.panicMode = false;

  advance();

  while (!match(TOKEN_EOF))
  {
    declaration();
  }

  endCompiler();
  return !parser.hadError;
}
