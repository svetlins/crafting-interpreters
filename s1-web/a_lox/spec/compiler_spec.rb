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
        JUMP-ON-FALSE 0 7
        POP
        LOAD-CONSTANT 0
        PRINT
        JUMP 0 4
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
        JUMP-ON-FALSE 0 7
        POP
        LOAD-CONSTANT 0
        PRINT
        JUMP 0 1
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
        JUMP-ON-FALSE 0 7
        POP
        LOAD-CONSTANT 0
        PRINT
        JUMP 255 245
        POP
    CODE
  end
end
