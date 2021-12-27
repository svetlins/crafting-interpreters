require "spec_helper"

RSpec.describe StaticResolver do
  def resolve(source)
    tokens = Scanner.new(source).scan
    ast = Parser.new(tokens).parse

    resolver = StaticResolver.new(error_reporter: self)
    resolver.resolve(ast)

    ast
  end

  it "adds stack_slot to variable statements" do
    source = <<-LOX
      fun fn() {
        var x = 1;
        var y = 2;
        var z = 3;

        {
          var b = 4;

          print b;
        }

        var b = 5;

        print x;
        print b;
      }
    LOX

    ast = resolve(source)

    expect(ast.first.body[0].stack_slot).to eq(0)
    expect(ast.first.body[1].stack_slot).to eq(1)
    expect(ast.first.body[2].stack_slot).to eq(2)

    expect(ast.first.body[3].statements[0].stack_slot).to eq(3)
    expect(ast.first.body[4].stack_slot).to eq(3)
  end

  it "adds stack_slot to variable expressions" do
    source = <<-LOX
      fun fn() {
        var x = 1;
        var y = 2;
        var z = 3;

        {
          var b = 4;

          print b;
        }

        var b = 5;

        print x;
        print b;
      }
    LOX

    ast = resolve(source)

    expect(ast.first.body[-4].statements[-1].expression.stack_slot).to eq(3)
    expect(ast.first.body[-2].expression.stack_slot).to eq(0)
    expect(ast.first.body[-1].expression.stack_slot).to eq(3)
  end

  it "does something with closures" do
    source = <<-LOX
      fun outer() {
        var x = 1;
        var y = 2;
        var z = 3;

        fun inner() {
          print x;
        }
      }
    LOX

    ast = resolve(source)

    binding.irb
  end
end
