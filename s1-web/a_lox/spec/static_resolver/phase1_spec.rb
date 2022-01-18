require "spec_Helper"

module ALox::StaticResolver
  RSpec.describe Phase1 do
    specify "infers global allocation to top level variables" do
      program = <<-LOX
        var x;
      LOX

      expect(program).to have_ast_attribute(:global, at: "0.allocation.kind")
    end

    specify "infers local allocation to variables in as block" do
      program = <<-LOX
        {
          var x;
        }
      LOX

      expect(program).to have_ast_attribute(:local, at: "0.statements.0.allocation.kind")
    end

    specify "infers local allocation to variables in a function" do
      program = <<-LOX
        fun fn() {
          var x;
        }
      LOX

      expect(program).to have_ast_attribute(:local, at: "0.body.0.allocation.kind")
    end

    specify "infers heap allocation for closed over variables in a function" do
      program = <<-LOX
        fun fn() {
          var x;
          fun inner() {
            x;
          }
        }
      LOX

      expect(program).to have_ast_attribute(:heap_allocated, at: "0.body.0.allocation.kind")
    end

    specify "infers heap allocation for closed over variables in a deeply nested function" do
      program = <<-LOX
        fun fn() {
          var x;
          fun inner1() {
            fun inner2() {
              fun inner3() {
                fun inner4() {
                  x;
                }
              }
            }
          }
        }
      LOX

      expect(program).to have_ast_attribute(:heap_allocated, at: "0.body.0.allocation.kind")
    end

    specify "infers global allocation to top level variable usages" do
      program = <<-LOX
        var x;
        print x;
      LOX

      expect(program).to have_ast_attribute(:global, at: "1.expression.allocation.kind")
    end

    specify "infers local allocation to variable usages in as block" do
      program = <<-LOX
        {
          var x;
          print x;
        }
      LOX

      expect(program).to have_ast_attribute(:local, at: "0.statements.1.expression.allocation.kind")
    end

    specify "infers local allocation to variable usages in a function" do
      program = <<-LOX
        fun fn() {
          var x;
          print x;
        }
      LOX

      expect(program).to have_ast_attribute(:local, at: "0.body.1.expression.allocation.kind")
    end

    specify "infers heap allocation for closed over variable usages in a function" do
      program = <<-LOX
        fun fn() {
          var x;
          fun inner() {
            print x;
          }
        }
      LOX

      expect(program).to have_ast_attribute(:heap_allocated, at: "0.body.1.body.0.expression.allocation.kind")
    end

    specify "infers heap allocation for closed over variables in a deeply nested function" do
      program = <<-LOX
        fun fn() {
          var x;
          fun inner1() {
            fun inner2() {
              fun inner3() {
                fun inner4() {
                  print x;
                }
              }
            }
          }
        }
      LOX

      expect(program).to have_ast_attribute(
        :heap_allocated,
        at: "0.body.1.body.0.body.0.body.0.body.0.expression.allocation.kind"
      )
    end
  end
end
