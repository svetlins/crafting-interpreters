require "spec_helper"

RSpec.describe ALox::Compiler do
  specify "globals" do
    source = <<-LOX
      var x = 1;
      print x;
    LOX

    expect(source).to compile_to <<-CODE
      __toplevel__:
        LOAD-CONSTANT 0
        DEFINE-GLOBAL 1
        GET-GLOBAL 1
        PRINT
        NIL
        RETURN
    CODE
  end

  specify "global assignment" do
    source = <<-LOX
      var x;
      x = 1;
      print x;
    LOX

    expect(source).to compile_to <<-CODE
      __toplevel__:
        NIL
        DEFINE-GLOBAL 0
        LOAD-CONSTANT 1
        SET-GLOBAL 0
        POP
        GET-GLOBAL 0
        PRINT
        NIL
        RETURN
    CODE
  end

  specify "global variable default initializer" do
    source = <<-LOX
      var x;
      print x;
    LOX

    expect(source).to compile_to <<-CODE
    __toplevel__:
      NIL
      DEFINE-GLOBAL 0
      GET-GLOBAL 0
      PRINT
      NIL
      RETURN
    CODE
  end

  specify "global block" do
    source = <<-LOX
      {
        var x = 1;
        print x;
      }
    LOX

    expect(source).to compile_to <<-CODE
      __toplevel__:
        LOAD-CONSTANT 0
        GET-LOCAL 0
        PRINT
        POP
        NIL
        RETURN
    CODE
  end

  specify "assignment in global block" do
    source = <<-LOX
      {
        var x;
        x = 1;
        print x;
      }
    LOX

    expect(source).to compile_to <<-CODE
      __toplevel__:
        NIL
        LOAD-CONSTANT 0
        SET-LOCAL 0
        POP
        GET-LOCAL 0
        PRINT
        POP
        NIL
        RETURN
    CODE
  end

  specify "if with else" do
    source = <<-LOX
      if (true) {
        print 1;
      } else {
        print 2;
      }
    LOX

    expect(source).to compile_to <<-CODE
      __toplevel__:
        TRUE
        JUMP-ON-FALSE +7
        POP
        LOAD-CONSTANT 0
        PRINT
        JUMP +4
        POP
        LOAD-CONSTANT 1
        PRINT
        NIL
        RETURN
    CODE
  end

  specify "if without else" do
    source = <<-LOX
      if (true) {
        print 1;
      }
    LOX

    expect(source).to compile_to <<-CODE
      __toplevel__:
        TRUE
        JUMP-ON-FALSE +7
        POP
        LOAD-CONSTANT 0
        PRINT
        JUMP +1
        POP
        NIL
        RETURN
    CODE
  end

  specify "while" do
    source = <<-LOX
      while (true) {
        print 1;
      }
    LOX

    expect(source).to compile_to <<-CODE
      __toplevel__:
        TRUE
        JUMP-ON-FALSE +7
        POP
        LOAD-CONSTANT 0
        PRINT
        JUMP -11
        POP
        NIL
        RETURN
    CODE
  end

  specify "for" do
    source = <<-LOX
      for(var x = 0; x < 10; x = x + 1) {
        print x;
      }
    LOX

    expect(source).to compile_to <<-CODE
      __toplevel__:
        LOAD-CONSTANT 0
        GET-LOCAL 0
        LOAD-CONSTANT 1
        LESSER
        JUMP-ON-FALSE +15
        POP
        GET-LOCAL 0
        PRINT
        GET-LOCAL 0
        LOAD-CONSTANT 2
        ADD
        SET-LOCAL 0
        POP
        JUMP -23
        POP
        POP # why this pop?
        NIL
        RETURN
    CODE
  end

  specify "function" do
    source = <<-LOX
      fun fn() {
        print 1;
      }
    LOX

    expect(source).to compile_to <<-CODE
      __toplevel__:
        LOAD-CLOSURE 1
        DEFINE-GLOBAL 2
        NIL
        RETURN
      __global__fn__:
        LOAD-CONSTANT 0
        PRINT
        NIL
        RETURN
    CODE
  end

  specify "function parameter" do
    source = <<-LOX
      fun fn(x) {
        print x;
      }
    LOX

    expect(source).to compile_to <<-CODE
      __toplevel__:
        LOAD-CLOSURE 0
        DEFINE-GLOBAL 1
        NIL
        RETURN
      __global__fn__:
        GET-LOCAL 0
        PRINT
        NIL
        RETURN
    CODE
  end

  specify "function return" do
    source = <<-LOX
      fun fn() {
        return 42;
      }
    LOX

    expect(source).to compile_to <<-CODE
      __toplevel__:
        LOAD-CLOSURE 1
        DEFINE-GLOBAL 2
        NIL
        RETURN
      __global__fn__:
        LOAD-CONSTANT 0
        RETURN
        NIL
        RETURN
    CODE
  end

  specify "function local" do
    source = <<-LOX
      fun fn() {
        var x = 1;
        print x;
      }
    LOX

    expect(source).to compile_to <<-CODE
      __toplevel__:
        LOAD-CLOSURE 1
        DEFINE-GLOBAL 2
        NIL
        RETURN
      __global__fn__:
        LOAD-CONSTANT 0
        GET-LOCAL 0
        PRINT
        NIL
        RETURN
    CODE
  end

  specify "inner function" do
    source = <<-LOX
      fun fn() {
        fun inner() {
          print 1;
        }
      }
    LOX

    expect(source).to compile_to <<-CODE
      __toplevel__:
        LOAD-CLOSURE 2
        DEFINE-GLOBAL 3
        NIL
        RETURN
      __global__fn__:
        LOAD-CLOSURE 1
        NIL
        RETURN
      __global__fn__inner__:
        LOAD-CONSTANT 0
        PRINT
        NIL
        RETURN
    CODE
  end

  specify "closure" do
    source = <<-LOX
      fun fn() {
        var x = 42;

        fun inner() {
          print x;
        }
      }
    LOX

    expect(source).to compile_to <<-CODE
      __toplevel__:
        LOAD-CLOSURE 2
        DEFINE-GLOBAL 3
        NIL
        RETURN
      __global__fn__:
        LOAD-CONSTANT 0
        LOAD-CLOSURE 1
          LOCAL 0
        NIL
        RETURN
      __global__fn__inner__:
        GET-UPVALUE 0
        PRINT
        NIL
        RETURN
    CODE
  end

  specify "multiple closure" do
    source = <<-LOX
      fun fn() {
        var x = 1;
        var y = 2;

        fun inner() {
          print x + y;
        }
      }
    LOX

    expect(source).to compile_to <<-CODE
      __toplevel__:
        LOAD-CLOSURE 3
        DEFINE-GLOBAL 4
        NIL
        RETURN
      __global__fn__:
        LOAD-CONSTANT 0
        LOAD-CONSTANT 1
        LOAD-CLOSURE 2
          LOCAL 0
          LOCAL 1
        NIL
        RETURN
      __global__fn__inner__:
        GET-UPVALUE 0
        GET-UPVALUE 1
        ADD
        PRINT
        NIL
        RETURN
    CODE
  end

  specify 'deep closure' do
    source = <<-LOX
      fun outer() {
        var x = 1;

        fun middle() {
          fun inner() {
            print x;
          }

          return inner;
        }
      }
    LOX

    expect(source).to compile_to <<-CODE
      __toplevel__:
        LOAD-CLOSURE 3
        DEFINE-GLOBAL 4
        NIL
        RETURN
      __global__outer__:
        LOAD-CONSTANT 0
        LOAD-CLOSURE 2
          LOCAL 0
        NIL
        RETURN
      __global__outer__middle__:
        LOAD-CLOSURE 1
          UPVALUE 0
        GET-LOCAL 0
        RETURN
        NIL
        RETURN
      __global__outer__middle__inner__:
        GET-UPVALUE 0
        PRINT
        NIL
        RETURN
    CODE

  end

  specify 'global block closure' do
    source = <<-LOX
      var fn;
      {
        var x = 1;
        fun inner() {
          return x;
        }

        fn = inner;
      }
    LOX

    expect(source).to compile_to <<-CODE
      __toplevel__:
        NIL
        DEFINE-GLOBAL 0
        LOAD-CONSTANT 1
        LOAD-CLOSURE 2
          LOCAL 0
        GET-LOCAL 1
        SET-GLOBAL 0
        POP
        CLOSE-UPVALUE
        POP
        NIL
        RETURN
      __global__inner__:
       GET-UPVALUE 0
       RETURN
       NIL
       RETURN
    CODE
  end

  specify "function call" do
    source = <<-LOX
      fun fn() {
        print 1;
      }

      fn();
    LOX

    expect(source).to compile_to <<-CODE
      __toplevel__:
        LOAD-CLOSURE 1
        DEFINE-GLOBAL 2
        GET-GLOBAL 2
        CALL 0
        POP
        NIL
        RETURN
      __global__fn__:
        LOAD-CONSTANT 0
        PRINT
        NIL
        RETURN
    CODE
  end

  specify "function call with parameters" do
    source = <<-LOX
      fun fn(x, y) {
        print x + y;
      }

      fn(1, 2);
    LOX

    expect(source).to compile_to <<-CODE
      __toplevel__:
        LOAD-CLOSURE 0
        DEFINE-GLOBAL 1
        GET-GLOBAL 1
        LOAD-CONSTANT 2
        LOAD-CONSTANT 3
        CALL 2
        POP
        NIL
        RETURN
      __global__fn__:
        GET-LOCAL 0
        GET-LOCAL 1
        ADD
        PRINT
        NIL
        RETURN
    CODE
  end

  specify "closure from block" do
    source = <<-LOX
      fun fn(x) {
        var fn;

        {
          fun inner() {
            return x;
          }

          fn = inner;
        }

        return fn;
      }

      fn(1)();
    LOX

    expect(source).to compile_to <<-CODE
      __toplevel__:
        LOAD-CLOSURE 1
        DEFINE-GLOBAL 2
        GET-GLOBAL 2
        LOAD-CONSTANT 3
        CALL 1
        CALL 0
        POP
        NIL
        RETURN
      __global__fn__:
        NIL
        LOAD-CLOSURE 0
          LOCAL 0
        GET-LOCAL 2
        SET-LOCAL 1
        POP
        POP
        GET-LOCAL 1
        RETURN
        NIL
        RETURN
      __global__fn__inner__:
        GET-UPVALUE 0
        RETURN
        NIL
        RETURN
    CODE
  end
end
