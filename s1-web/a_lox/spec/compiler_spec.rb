require "spec_helper"

RSpec.describe ALox::Compiler do
  specify "globals" do
    source = <<-LOX
      var x = 1;
      print x;
    LOX

    expect(source).to compile_to <<-CODE
      __script__:
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
      __script__:
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

  specify "block" do
    source = <<-LOX
      {
        var x = 1;
        print x;
      }
    LOX

    expect(source).to compile_to <<-CODE
      __script__:
        LOAD-CONSTANT 0
        GET-LOCAL 0
        PRINT
        POP
        NIL
        RETURN
    CODE
  end

  specify "assignment in block" do
    source = <<-LOX
      {
        var x;
        x = 1;
        print x;
      }
    LOX

    expect(source).to compile_to <<-CODE
      __script__:
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
      __script__:
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
      __script__:
        TRUE
        JUMP-ON-FALSE +7
        POP
        LOAD-CONSTANT 0
        PRINT
        JUMP +1
        POP
    CODE
  end

  specify "while" do
    source = <<-LOX
      while (true) {
        print 1;
      }
    LOX

    expect(source).to compile_to <<-CODE
      __script__:
        TRUE
        JUMP-ON-FALSE +7
        POP
        LOAD-CONSTANT 0
        PRINT
        JUMP -11
        POP
    CODE
  end

  specify "for" do
    source = <<-LOX
      for(var x = 0; x < 10; x = x + 1) {
        print x;
      }
    LOX

    expect(source).to compile_to <<-CODE
      __script__:
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
    CODE
  end

  specify "functions" do
    source = <<-LOX
      fun fn() {
        print 1;
      }
    LOX

    expect(source).to compile_to <<-CODE
      __script__:
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

  specify "function parameters" do
    source = <<-LOX
      fun fn(x) {
        print x;
      }
    LOX

    expect(source).to compile_to <<-CODE
      __script__:
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
      __script__:
        LOAD-CLOSURE 1
        DEFINE-GLOBAL 2
        NIL
        RETURN
      __global__fn__:
        LOAD-CONSTANT 0
        RETURN
    CODE
  end

  specify "function locals" do
    source = <<-LOX
      fun fn() {
        var x = 1;
        print x;
      }
    LOX

    expect(source).to compile_to <<-CODE
      __script__:
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

  specify "inner functions" do
    source = <<-LOX
      fun fn() {
        fun inner() {
          print 1;
        }
      }
    LOX

    expect(source).to compile_to <<-CODE
      __script__:
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

  specify "closures" do
    source = <<-LOX
      fun fn() {
        var x = 42;

        fun inner() {
          print x;
        }
      }
    LOX

    expect(source).to compile_to <<-CODE
      __script__:
        LOAD-CLOSURE 2
        DEFINE-GLOBAL 3
        NIL
        RETURN
      __global__fn__:
        LOAD-CONSTANT 0
        INIT-HEAP H-XXX
        LOAD-CLOSURE 1
        NIL
        RETURN
      __global__fn__inner__:
        GET-HEAP H-XXX
        PRINT
        NIL
        RETURN
    CODE
  end
end
