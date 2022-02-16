require 'spec_helper'

module ALox
  RSpec.describe UpvalueCompiler do
    it "does something" do
      source = <<-LOX
        fun outer() {
          var x = 1;

          fun middle() {
            fun inner() {
              print x;
              x = 5;
            }
          }
        }
      LOX

      expect(source).to compile_to2 <<-CODE
      __toplevel__:
        LOAD-CLOSURE 4
        DEFINE-GLOBAL 5
        NIL
        RETURN
      outer:
        LOAD-CONSTANT 0
        LOAD-CLOSURE 3
        NIL
        RETURN
      middle:
        LOAD-CLOSURE 2
        NIL
        RETURN
      inner:
        GET-UPVALUE 0
        PRINT
        LOAD-CONSTANT 1
        SET-UPVALUE 0
        POP
        NIL
        RETURN
      CODE
    end

    it "does something with multiple upvalues" do
      source = <<-LOX
        fun outer() {
          var x = 1;
          var y = 2;

          fun middle() {
            fun inner() {
              x;
              print y;
            }
          }
        }
      LOX

      expect(source).to compile_to2 <<-CODE
      __toplevel__:
        LOAD-CLOSURE 4
        DEFINE-GLOBAL 5
        NIL
        RETURN
      outer:
        LOAD-CONSTANT 0
        LOAD-CONSTANT 1
        LOAD-CLOSURE 3
        NIL
        RETURN
      middle:
        LOAD-CLOSURE 2
        NIL
        RETURN
      inner:
        GET-UPVALUE 0
        POP
        GET-UPVALUE 1
        PRINT
        NIL
        RETURN
      CODE
    end
  end
end
