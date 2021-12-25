require "spec_helper"

RSpec.describe Compiler do
  def compile(source)
    tokens = Scanner.new(source).scan
    ast = Parser.new(tokens).parse

    resolver = StaticResolver.new(error_reporter: self)
    resolver.resolve(ast)

    bytecode = Compiler.new(ast).compile
  end

  it "compiles arithmetic correctly" do
    chunk = compile <<-LOX
      1 + 2 * 3;
    LOX

    expect(chunk.code).to eq([
      "LOAD-CONSTANT", 0,
      "LOAD-CONSTANT", 1,
      "LOAD-CONSTANT", 2,
      "MULTIPLY",
      "ADD",
      "POP"
    ])

    expect(chunk.constants).to eq([
      1.0,
      2.0,
      3.0,
    ])
  end

  it "compiles if/then/else correctly" do
    chunk = compile <<-LOX
      if (1 + 2) {
        print "Oh, yes";
        print "It's true!";
      } else {
        print ":( it's false";
        print "Unfortunately ;(";
      }
    LOX

    expect(chunk.code).to eq([
      "LOAD-CONSTANT", 0,
      "LOAD-CONSTANT", 1,
      "ADD",
      "JUMP-ON-FALSE", 0, 10,
      "POP",
      "LOAD-CONSTANT", 2,
      "PRINT",
      "LOAD-CONSTANT", 3,
      "PRINT",
      "JUMP", 0, 7,
      "POP",
      "LOAD-CONSTANT", 4,
      "PRINT",
      "LOAD-CONSTANT", 5,
      "PRINT"
    ])
  end

  it "compiles local variables correctly" do
    chunk = compile <<-LOX
      var outer = 100;

      {
        var dummy = "dummy";
        var x = 32 + 42;
        var y = 200;
        print x + y;

        outer = 100;
        x = 100;
      }
    LOX

    expect(chunk.code).to eq([
      "LOAD-CONSTANT", 0,
      "DEFINE-GLOBAL", 1,
      "LOAD-CONSTANT", 2,
      "LOAD-CONSTANT", 3,
      "LOAD-CONSTANT", 4,
      "ADD",
      "LOAD-CONSTANT", 5,
      "GET-LOCAL", 1,
      "GET-LOCAL", 2,
      "ADD",
      "PRINT",
      "LOAD-CONSTANT", 6,
      "SET-GLOBAL", 7,
      "POP",
      "LOAD-CONSTANT", 8,
      "SET-LOCAL", 1,
      "POP",
      "POP",
      "POP",
      "POP"
    ])

    expect(chunk.constants).to eq([
      100.0,     # 0
      "outer",   # 1
      "dummy",   # 2
      32.0,      # 3
      42.0,      # 4
      200.0,     # 5
      100.0,     # 6
      "outer",   # 7
      100.0      # 8
    ])
  end
end