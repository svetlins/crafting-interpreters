require 'spec_helper'

module ALox
  RSpec.describe Compiler do
    it "does something" do
      source = <<-LOX
        fun outer(y) {
          var x = 1;

          fun middle() {
            fun inner() {
              print x;
              x = 5;
            }
          }
        }
      LOX

      expect(source).to compile_to <<-CODE
        __toplevel__:
          LOAD-CLOSURE 4
          DEFINE-GLOBAL 5
          NIL
          RETURN
        __global__outer__:
          LOAD-CONSTANT 0
          LOAD-CLOSURE 3 1 1
          NIL
          RETURN
        __global__outer__middle__:
          LOAD-CLOSURE 2 0 0
          NIL
          RETURN
        __global__outer__middle__inner__:
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
              return x + y;
            }
          }
        }
      LOX

      expect(source).to compile_to <<-CODE
        __toplevel__:
          LOAD-CLOSURE 4
          DEFINE-GLOBAL 5
          NIL
          RETURN
        __global__outer__:
          LOAD-CONSTANT 0
          LOAD-CONSTANT 1
          LOAD-CLOSURE 3 1 0 1 1
          NIL
          RETURN
        __global__outer__middle__:
          LOAD-CLOSURE 2 0 0 0 1
          NIL
          RETURN
        __global__outer__middle__inner__:
          GET-UPVALUE 0
          GET-UPVALUE 1
          ADD
          RETURN
          NIL
          RETURN
      CODE
    end
  end
end
