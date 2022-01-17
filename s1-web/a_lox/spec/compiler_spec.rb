require "spec_helper"

module ALox
  RSpec.describe Compiler do
    it "compiles global variables" do
      source = <<-LOX
        var x = 1;
        var y = 2;
        print x;
        print y;
      LOX

#       "LOAD-CONSTANT", 0, "DEFINE-GLOBAL", 1, "LOAD-CONSTANT", 2, "DEFINE-GLOBAL", 3, "GET-GLOBAL", 1, "PRINT", "GET-GLOBAL", 3, "PRINT", "NIL", "RETURN",
      expect(source).to compile_to(<<-OPS)
        __script__:
          LOAD-CONSTANT 0
          DEFINE-GLOBAL 1
          LOAD-CONSTANT 2
          DEFINE-GLOBAL 3
          GET-GLOBAL 1
          PRINT
          GET-GLOBAL 3
          PRINT
          NIL
          RETURN
      OPS
    end
  end

  RSpec.xdescribe Compiler do
    it "compiles functions" do
      executable = compile <<-LOX
        fun fn() {
          print 42;
        }
      LOX

      expect(executable.as_json).to eq(
        { "__global__fn__" => { code: ["LOAD-CONSTANT", 0, "PRINT", "NIL", "RETURN"], constants: [42.0] },
        "__script__" => { code: ["LOAD-CLOSURE", 0, "DEFINE-GLOBAL", 1, "NIL", "RETURN"],
                          constants: [{ type: :function, arity: 0, name: "__global__fn__" }, "fn"] } }
      )
    end

    it "compiles global variables" do
      source = <<-LOX
        var x = 1;
        var y = 2;
        print x;
        print y;
      LOX

      expect(executable.as_json).to eq(
        { "__script__" => {
          :code => [
            "LOAD-CONSTANT", 0, "DEFINE-GLOBAL", 1, "LOAD-CONSTANT", 2, "DEFINE-GLOBAL", 3, "GET-GLOBAL", 1, "PRINT", "GET-GLOBAL", 3, "PRINT", "NIL", "RETURN",
          ],
          :constants => [1.0, "x", 2.0, "y"],
        } }
      )
    end

    it "compiles assignment to global variables" do
      executable = compile <<-LOX
        var x = 1;
        x = 2;
      LOX

      expect(executable.as_json).to eq(
        { "__script__" => {
          :code => [
            "LOAD-CONSTANT", 0, "DEFINE-GLOBAL", 1, "LOAD-CONSTANT", 2, "SET-GLOBAL", 1, "POP", "NIL", "RETURN",
          ],
          :constants => [1.0, "x", 2.0],
        } }
      )
    end

    it "compiles local variables" do
      executable = compile <<-LOX
        fun fn() {
          var x = 1;
          var y = 2;
        }
      LOX

      expect(executable.as_json).to eq(
        {
          "__global__fn__" => { :code => ["LOAD-CONSTANT", 0, "LOAD-CONSTANT", 1, "NIL", "RETURN"], :constants => [1.0, 2.0] },
          "__script__" => { :code => ["LOAD-CLOSURE", 0, "DEFINE-GLOBAL", 1, "NIL", "RETURN"], :constants => [{ :type => :function, :arity => 0, :name => "__global__fn__" }, "fn"] },
        }
      )
    end

    it "compiles assignment to local variables" do
      executable = compile <<-LOX
        fun fn() {
          var x = 1;
          var y = 2;
          var z = 3;
          print 1;
          y = 4;
        }
      LOX

      expect(executable.as_json).to eq(
        {
          "__global__fn__" => { :code => ["LOAD-CONSTANT", 0, "LOAD-CONSTANT", 1, "LOAD-CONSTANT", 2, "LOAD-CONSTANT", 0, "PRINT", "LOAD-CONSTANT", 3, "SET-LOCAL", 1, "POP", "NIL", "RETURN"], :constants => [1.0, 2.0, 3.0, 4.0] },
          "__script__" => { :code => ["LOAD-CLOSURE", 0, "DEFINE-GLOBAL", 1, "NIL", "RETURN"], :constants => [{ :type => :function, :arity => 0, :name => "__global__fn__" }, "fn"] },
        }
      )
    end

    it "compiles heap allocated variables" do
      executable = compile <<-LOX
        fun outer() {
          var x = 1;

          fun inner() {
            print x;
          }
        }
      LOX

      expect(executable.as_json).to match(
        {
          "__global__outer__" => { :code => ["LOAD-CONSTANT", 0, "INIT-HEAP", kind_of(Numeric), "LOAD-CLOSURE", 1, "NIL", "RETURN"], :constants => [1.0, { :type => :function, :arity => 0, :name => "__global__outer__inner__" }] },
          "__global__outer__inner__" => { :code => ["GET-HEAP", kind_of(Numeric), "PRINT", "NIL", "RETURN"], :constants => [] },
          "__script__" => { :code => ["LOAD-CLOSURE", 0, "DEFINE-GLOBAL", 1, "NIL", "RETURN"], :constants => [{ :type => :function, :arity => 0, :name => "__global__outer__" }, "outer"] },
        }
      )
    end

    it "compiles parameters" do
      executable = compile <<-LOX
        fun fn(a, b) {
          var c = 1;

          print a;
          print b;
          print c;
        }
      LOX

      expect(executable.as_json).to eq(
        {
          "__global__fn__" => { :code => ["LOAD-CONSTANT", 0, "GET-LOCAL", 0, "PRINT", "GET-LOCAL", 1, "PRINT", "GET-LOCAL", 2, "PRINT", "NIL", "RETURN"], :constants => [1.0] },
          "__script__" => { :code => ["LOAD-CLOSURE", 0, "DEFINE-GLOBAL", 1, "NIL", "RETURN"], :constants => [{ :type => :function, :arity => 2, :name => "__global__fn__" }, "fn"] },
        }
      )
    end
  end

  # RSpec.xdescribe Compiler do
  #   def compile(source)
  #     tokens = Scanner.new(source).scan
  #     ast = Parser.new(tokens).parse

  #     resolver = StaticResolver.new(error_reporter: self)
  #     resolver.resolve(ast)

  #     bytecode = Compiler.new(ast).compile
  #   end

  #   it "compiles arithmetic correctly" do
  #     executable = compile <<-LOX
  #       1 + 2 * 3;
  #     LOX

  #     expect(executable.code).to eq([
  #       "LOAD-CONSTANT", 0,
  #       "LOAD-CONSTANT", 1,
  #       "LOAD-CONSTANT", 2,
  #       "MULTIPLY",
  #       "ADD",
  #       "POP"
  #     ])

  #     expect(executable.constants).to eq([
  #       1.0,
  #       2.0,
  #       3.0
  #     ])
  #   end

  #   it "compiles if/then/else correctly" do
  #     executable = compile <<-LOX
  #       if (1 + 2) {
  #         print "Oh, yes";
  #         print "It's true!";
  #       } else {
  #         print ":( it's false";
  #         print "Unfortunately ;(";
  #       }
  #     LOX

  #     expect(executable.code).to eq([
  #       "LOAD-CONSTANT", 0,
  #       "LOAD-CONSTANT", 1,
  #       "ADD",
  #       "JUMP-ON-FALSE", 0, 10,
  #       "POP",
  #       "LOAD-CONSTANT", 2,
  #       "PRINT",
  #       "LOAD-CONSTANT", 3,
  #       "PRINT",
  #       "JUMP", 0, 7,
  #       "POP",
  #       "LOAD-CONSTANT", 4,
  #       "PRINT",
  #       "LOAD-CONSTANT", 5,
  #       "PRINT"
  #     ])
  #   end

  #   it "compiles `and` expressions correctly" do
  #     executable = compile <<-LOX
  #       1 and 2;
  #     LOX

  #     expect(executable.code).to eq([
  #       "LOAD-CONSTANT", 0,
  #       "JUMP-ON-FALSE", 0, 3,
  #       "POP",
  #       "LOAD-CONSTANT", 1,

  #       "POP"
  #     ])
  #   end

  #   it "compiles `or` expressions correctly" do
  #     executable = compile <<-LOX
  #       1 or 2;
  #     LOX

  #     expect(executable.code).to eq([
  #       "LOAD-CONSTANT", 0,
  #       "JUMP-ON-FALSE", 0, 3,
  #       "JUMP", 0, 3,
  #       "POP",
  #       "LOAD-CONSTANT", 1,

  #       "POP"
  #     ])
  #   end

  #   it "compiles local variables correctly" do
  #     executable = compile <<-LOX
  #       var outer = 100;

  #       {
  #         var dummy = "dummy";
  #         var x = 32 + 42;
  #         var y = 200;
  #         print x + y;

  #         outer = 100;
  #         x = 100;
  #       }
  #     LOX

  #     expect(executable.code).to eq([
  #       "LOAD-CONSTANT", 0,
  #       "DEFINE-GLOBAL", 1,
  #       "LOAD-CONSTANT", 2,
  #       "LOAD-CONSTANT", 3,
  #       "LOAD-CONSTANT", 4,
  #       "ADD",
  #       "LOAD-CONSTANT", 5,
  #       "GET-LOCAL", 1,
  #       "GET-LOCAL", 2,
  #       "ADD",
  #       "PRINT",
  #       "LOAD-CONSTANT", 6,
  #       "SET-GLOBAL", 7,
  #       "POP",
  #       "LOAD-CONSTANT", 8,
  #       "SET-LOCAL", 1,
  #       "POP",
  #       "POP",
  #       "POP",
  #       "POP"
  #     ])

  #     expect(executable.constants).to eq([
  #       100.0, # 0
  #       "outer", # 1
  #       "dummy", # 2
  #       32.0, # 3
  #       42.0, # 4
  #       200.0, # 5
  #       100.0, # 6
  #       "outer", # 7
  #       100.0 # 8
  #     ])
  #   end
  # end
end
