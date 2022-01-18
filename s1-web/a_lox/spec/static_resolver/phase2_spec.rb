require "spec_helper"

module ALox::StaticResolver
  RSpec.describe Phase2 do
    specify "block variables are on the stack" do
      program = <<-LOX
        {
          var x;
          var y;
        }
      LOX

      expect(program).to have_ast_attribute(0, at: "0.statements.0.allocation.stack_slot")
      expect(program).to have_ast_attribute(1, at: "0.statements.1.allocation.stack_slot")
    end

    specify "block variable access reads from the stack" do
      program = <<-LOX
        {
          var x;
          var y;
          print x;
          print y;
        }
      LOX

      expect(program).to have_ast_attribute(0, at: "0.statements.2.expression.allocation.stack_slot")
      expect(program).to have_ast_attribute(1, at: "0.statements.3.expression.allocation.stack_slot")
    end

    specify "nested blocks don't interfere" do
      program = <<-LOX
        {
          var x;

          {
            var y;
          }

          var z;
        }
      LOX

      expect(program).to have_ast_attribute(0, at: "0.statements.0.allocation.stack_slot")
      expect(program).to have_ast_attribute(1, at: "0.statements.1.statements.0.allocation.stack_slot")
      expect(program).to have_ast_attribute(1, at: "0.statements.2.allocation.stack_slot")
    end

    specify "nested block variable access" do
      program = <<-LOX
        {
          var x;
          print x;

          {
            var y;
            print y;
          }

          var z;
          print z;
        }
      LOX

      expect(program).to have_ast_attribute(0, at: "0.statements.1.expression.allocation.stack_slot")
      expect(program).to have_ast_attribute(1, at: "0.statements.2.statements.1.expression.allocation.stack_slot")
      expect(program).to have_ast_attribute(1, at: "0.statements.4.expression.allocation.stack_slot")
    end

    specify "function variables are on the stack" do
      program = <<-LOX
        fun fn() {
          var x;
          var y;
        }
      LOX

      expect(program).to have_ast_attribute(0, at: "0.body.0.allocation.stack_slot")
      expect(program).to have_ast_attribute(1, at: "0.body.1.allocation.stack_slot")
    end

    specify "function parameters are on the stack" do
      program = <<-LOX
        fun fn(x, y) {
          var z;
        }
      LOX

      expect(program).to have_ast_attribute(0, at: "0.parameter_allocations.0.stack_slot")
      expect(program).to have_ast_attribute(1, at: "0.parameter_allocations.1.stack_slot")

      expect(program).to have_ast_attribute(2, at: "0.body.0.allocation.stack_slot")
    end

    specify "closed over variables on the heap don't interfere with stack slot enumeration" do
      program = <<-LOX
        fun fn() {
          var x;
          var y;
          var z;

          fun inner() {
            return y;
          }
        }
      LOX

      expect(program).to have_ast_attribute(0, at: "0.body.0.allocation.stack_slot")
      expect(program).to have_ast_attribute(1, at: "0.body.2.allocation.stack_slot")
    end

    it "assigns full name to functions" do
      program = <<-LOX
        fun outer() {
          fun inner() {
            print x;
          }
        }
      LOX

      expect(program).to have_ast_attribute("__global__outer__", at: "0.full_name")
      expect(program).to have_ast_attribute("__global__outer__inner__", at: "0.body.0.full_name")
    end
  end
end
