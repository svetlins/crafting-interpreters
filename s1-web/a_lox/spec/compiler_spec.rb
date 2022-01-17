require "spec_helper"

module ALox
  RSpec.describe Compiler do
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
  end
end
