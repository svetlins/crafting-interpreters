require "spec_helper"
require "stringio"

RSpec.describe VM do
  def execute(source)
    tokens = Scanner.new(source).scan
    ast = Parser.new(tokens).parse
    chunk = Chunk.new

    phase1 = ::StaticResolver::Phase1.new(error_reporter: nil)
    phase2 = ::StaticResolver::Phase2.new(error_reporter: nil)
    phase1.resolve(ast)
    phase2.resolve(ast)

    Compiler.new(ast, chunk).compile

    stdout = StringIO.new

    VM.execute(chunk, out: stdout)

    stdout.tap(&:rewind).read.chomp
  end

  it "can print" do
    source = <<-LOX
      print 42;
    LOX

    expect(execute(source)).to eq("42.0")
  end

  it "can assign to locals" do
    source = <<-LOX
      fun fn() {
        var x = 41;

        x = x + 1;

        return x;
      }

      print fn();
    LOX

    expect(execute(source)).to eq("42.0")
  end

  it "handles blocks" do
    source = <<-LOX
      fun fn() {
        {
          var x = 42;
          print x;
        }

        var y = 69;
        print y;
      }

      fn();
    LOX

    expect(execute(source)).to eq("42.0\n69.0")
  end

  it "handles else branch of if" do
    source = <<-LOX
      fun fn() {
        if(1 == 2) {
          print "hmm";
        } else {
          print "nope";
        }

        var x = "preserves stack";

        print x;
      }

      fn();
    LOX

    expect(execute(source)).to eq("\"nope\"\n\"preserves stack\"")
  end

  it "handles then branch of if" do
    source = <<-LOX
      fun fn() {
        if(1 == 1) {
          print "yep";
        } else {
          print "hmm";
        }

        var x = "preserves stack";

        print x;
      }

      fn();
    LOX

    expect(execute(source)).to eq("\"yep\"\n\"preserves stack\"")
  end

  it "can handle closures (no assignment to closed variables)" do
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

  it "can handle closures (with assignment to closed variables)" do
    source = <<-LOX
      fun outer(x) {
        var p = x;

        fun inner(r) {
          p = p + r;
          return p;
        }

        return inner;
      }

      var agg = outer(10);

      print agg(1);
      print agg(10);
      print agg(100);
    LOX

    expect(execute(source)).to eq("11.0\n21.0\n121.0")
  end

  context "(memory leaks)" do
    around do |example|
      GC.disable
      example.run
      GC.enable
    end

    def current_heap_values
      ObjectSpace.each_object.select { |obj| obj.class == VM::HeapValue }
    end

    it "does not leak" do
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

      ObjectSpace.garbage_collect

      expect(current_heap_values).to be_empty
    end
  end
end
