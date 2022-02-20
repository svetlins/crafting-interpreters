require "spec_helper"
require "stringio"

module ALox
  RSpec.describe VM do
    def execute(source, vm: nil)
      tokens = Scanner.new(source).scan
      ast = Parser.new(tokens).parse
      executable = ExecutableContainer.new

      StaticResolver::Upvalues.new.resolve(ast)
      Compiler.new(ast, executable).compile

      stdout = StringIO.new

      (vm || VM).execute(executable, out: stdout)

      stdout.tap(&:rewind).read.chomp
    end

    xcontext "(memory leaks)" do
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
