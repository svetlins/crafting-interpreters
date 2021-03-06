module ALox
  module Opcodes
    LOAD_CONSTANT = "LOAD-CONSTANT"
    LOAD_CLOSURE = "LOAD-CLOSURE"
    RETURN = "RETURN"

    ADD = "ADD"
    SUBTRACT = "SUBTRACT"
    MULTIPLY = "MULTIPLY"
    DIVIDE = "DIVIDE"

    EQUAL = "EQUAL"
    GREATER = "GREATER"
    LESSER = "LESSER"

    NOT = "NOT"
    NEGATE = "NEGATE"

    POP = "POP"
    TRUE_OP = "TRUE"
    FALSE_OP = "FALSE"
    NIL_OP = "NIL"

    PRINT = "PRINT"

    DEFINE_GLOBAL = "DEFINE-GLOBAL"
    GET_GLOBAL = "GET-GLOBAL"
    SET_GLOBAL = "SET-GLOBAL"

    GET_LOCAL = "GET-LOCAL"
    SET_LOCAL = "SET-LOCAL"

    SET_HEAP = "SET-HEAP"
    INIT_HEAP = "INIT-HEAP"
    GET_HEAP = "GET-HEAP"

    JUMP_ON_FALSE = "JUMP-ON-FALSE"
    JUMP = "JUMP"

    CALL = "CALL"
  end
end
