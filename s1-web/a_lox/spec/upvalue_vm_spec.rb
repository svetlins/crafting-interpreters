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

    it "works" do
      source = <<-LOX
        print 42;
      LOX

      expect(execute(source)).to eq('42.0')
    end

    it "no upvalues" do
      source = <<-LOX
        fun fn() {
          print 42;
        }

        fn();
      LOX

      expect(execute(source)).to eq('42.0')
    end

    it "yes open upvalues" do
      source = <<-LOX
        fun fn() {
          var x = 42;

          fun inner() {
            print x;
          }

          inner();
        }

        fn();
      LOX

      expect(execute(source)).to eq('42.0')
    end

    it "yes open multiple upvalues" do
      source = <<-LOX
        fun fn() {
          var x = 40;
          var y = 1;
          var z = 1;

          fun inner() {
            print x + y  + z;
          }

          inner();
        }

        fn();
      LOX

      expect(execute(source)).to eq('42.0')
    end

    it "yes open multiple deep upvalues" do
      source = <<-LOX
        fun fn() {
          var x = 40;
          var y = 1;
          var z = 1;

          fun middle() {
            fun inner() {
              print x + y + z;
            }

            return inner;
          }

          middle()();
        }

        fn();
      LOX

      expect(execute(source)).to eq('42.0')
    end

    it "yes closed upvalue" do
      source = <<-LOX
        fun fn() {
          var x = 42;

          fun inner() {
            print x;
          }

          return inner;
        }

        var closure = fn();
        closure();
      LOX

      expect(execute(source)).to eq('42.0')
    end

    it "yes closed deep upvalue" do
      source = <<-LOX
        fun fn() {
          var x = 41;

          fun middle() {
            var y = 1;

            fun inner() {
              return x + y;
            }

            return inner;
          }

          return middle;
        }

        var closure = fn()();

        print closure();
      LOX

      expect(execute(source)).to eq('42.0')
    end

    it "yes closed deep parameter upvalue" do
      source = <<-LOX
        fun fn(x) {
          fun middle(y) {
            fun inner() {
              return x + y;
            }

            return inner;
          }

          return middle;
        }

        var closure = fn(41)(1);

        print closure();
      LOX

      expect(execute(source)).to eq('42.0')
    end

    it "yes regression" do
      source = <<-LOX
        fun fn(x, y, z) {
          fun inner() {
            print x;
            fun inner1() {
              fun inner2() {
                fun inner3() {
                  fun inner4() {
                    return x * y * z;
                  }

                  return inner4;
                }
                return inner3;
              }
              return inner2;
            }
            return inner1;
          }

          return inner;
        }

        print fn(1, 2, 3)()()()()();
      LOX

      expect(execute(source)).to eq("1.0\n6.0")
    end

    it "yes regression 2" do
      source = <<-LOX
        fun outer() {
          var pad1 = 1;
          var pad2 = 2;

          fun fn(x, y, z) {
            fun inner() {
              print x;
              fun inner1() {
                fun inner2() {
                  fun inner3() {
                    fun inner4() {
                      return x * y * z;
                    }

                    return inner4;
                  }
                  return inner3;
                }
                return inner2;
              }
              return inner1;
            }

            return inner;
          }

          print fn(1, 2, 3)()()()()();
        }

        outer();
      LOX

      expect(execute(source)).to eq("1.0\n6.0")
    end
  end
end
