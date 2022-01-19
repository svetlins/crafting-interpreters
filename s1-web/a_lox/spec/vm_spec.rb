require "spec_helper"
require "stringio"

module ALox
  RSpec.describe VM do
    def execute(source, vm: nil)
      tokens = Scanner.new(source).scan
      ast = Parser.new(tokens).parse
      executable = ExecutableContainer.new

      phase1 = StaticResolver::Phase1.new(error_reporter: nil)
      phase2 = StaticResolver::Phase2.new(error_reporter: nil)
      phase1.resolve(ast)
      phase2.resolve(ast)

      Compiler.new(ast, executable).compile

      stdout = StringIO.new

      (vm || VM).execute(executable, out: stdout)

      stdout.tap(&:rewind).read.chomp
    end

    it "can print" do
      source = <<-LOX
        print 42;
      LOX

      expect(execute(source)).to eq("42.0")
    end

    it "handles grouping" do
      source = <<-LOX
        print (1 + 1) * 2;
      LOX

      expect(execute(source)).to eq("4.0")
    end

    it "manages the stack correctly" do
      source = <<-LOX
        fun other(a, b, c) {
          return a + b + c;
        }

        fun fn() {
          var x = 40;
          other(1,2,3);
          var y = 60;

          return x + y;
        }

        print fn();
      LOX

      expect(execute(source)).to eq("100.0")
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

      expect(execute(source)).to eq("nope\npreserves stack")
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

      expect(execute(source)).to eq("yep\npreserves stack")
    end

    it "handles while loops" do
      source = <<-LOX
        var x = 0;

        while (x < 3) {
          x = x + 1;
          print x;
        }
      LOX

      expect(execute(source)).to eq("1.0\n2.0\n3.0")
    end

    it "handles for loops" do
      source = <<-LOX
        for(var x = 0; x < 3; x = x + 1) {
          print x + 1;
        }
      LOX

      expect(execute(source)).to eq("1.0\n2.0\n3.0")
    end

    context "(binary ops)" do
      specify { expect(execute("print 1 > 2;")).to eq("false") }
      specify { expect(execute("print 3 > 2;")).to eq("true") }
      specify { expect(execute("print 1 >= 2;")).to eq("false") }
      specify { expect(execute("print 2 > 2;")).to eq("false") }
      specify { expect(execute("print 2 >= 2;")).to eq("true") }

      specify { expect(execute("print 1 < 0;")).to eq("false") }
      specify { expect(execute("print -1 < 0;")).to eq("true") }
      specify { expect(execute("print 1 <= 0;")).to eq("false") }
      specify { expect(execute("print 0 < 0;")).to eq("false") }
      specify { expect(execute("print 0 <= 0;")).to eq("true") }

      specify { expect(execute("print -5;")).to eq("-5.0") }
      specify { expect(execute("print !true;")).to eq("false") }

      specify { expect(execute("print 5 != 5;")).to eq("false") }
      specify { expect(execute("print 5 != 6;")).to eq("true") }
    end

    it "arithmetic precedence" do
      source = <<-LOX
        print 1 + 4 * 4 / 8 <= 3;
      LOX

      expect(execute(source)).to eq("true")
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
        ObjectSpace.each_object.select { |obj| obj.instance_of?(VM::HeapValue) }
      end

      it "does not leak" do
        source = <<-LOX
          fun program() {
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
          }

          program();
        LOX

        vm = VM.new

        execute(source, vm: vm)

        ObjectSpace.garbage_collect

        expect(current_heap_values).to be_empty
      end
    end
  end
end
