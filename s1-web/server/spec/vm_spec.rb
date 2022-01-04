require "spec_helper"
require "stringio"

RSpec.describe VM do
  def execute(source)
    tokens = Scanner.new(source).scan
    ast = Parser.new(tokens).parse
    chunk = Chunk.new

    phase1 = ::StaticResolver::Phase1.new(error_reporter: self)
    phase2 = ::StaticResolver::Phase2.new(error_reporter: self)
    phase1.resolve(ast)
    phase2.resolve(ast)

    Compiler.new(ast, chunk).compile

    stdout = StringIO.new

    VM.execute(chunk, out: stdout)

    stdout.tap(&:rewind).read.chomp
  end

  around do |example|
    stop = false
    tids = 10.times.map { Thread.new { GC.start while !stop } }
    example.run
    stop = true
    tids.each(&:join)
  end


  it "can print" do
    source = <<-LOX
      print 42;
    LOX

    expect(execute(source)).to eq("42.0")
  end

  it "can handle closures" do
    source = <<-LOX
      fun outer(x) {
        var p = x;

        fun middle(y) {
          var q = y;

          fun inner(r) {
            print p * q * r;
          }

          return inner;
        }

        return middle;
      }

      var h1 = outer(2);
      var h2 = outer(3);

      h2(5)(7);
      h1(11)(13);
    LOX

    expect(execute(source)).to eq("105.0\n286.0")
  end
end
