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

  specify "if" do
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
        JUMP 0 6
        POP
        LOAD-CONSTANT 1
        PRINT
        NIL
        RETURN
    CODE
  end
end
