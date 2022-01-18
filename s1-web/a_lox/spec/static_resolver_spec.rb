require "spec_helper"

module ALox
  module StaticResolver
    RSpec.describe Phase2 do
      specify "block variables are on the stack" do
        source = <<-LOX
          {
            var x;
            var y;
          }
        LOX

        expect(source).to have_slot(0, at: "0.statements.0")
        expect(source).to have_slot(1, at: "0.statements.1")
      end

      specify "block variable access read from the stack" do
        source = <<-LOX
          {
            var x;
            var y;
            print x;
            print y;
          }
        LOX

        expect(source).to have_slot(0, at: "0.statements.2.expression")
        expect(source).to have_slot(1, at: "0.statements.3.expression")
      end

      specify "nested blocks don't interfere" do
        source = <<-LOX
          {
            var x;

            {
              var y;
            }

            var z;
          }
        LOX

        expect(source).to have_slot(0, at: "0.statements.0")
        expect(source).to have_slot(1, at: "0.statements.1.statements.0")
        expect(source).to have_slot(1, at: "0.statements.2")
      end

      specify "nested block variable access" do
        source = <<-LOX
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

        expect(source).to have_slot(0, at: "0.statements.1.expression")
        expect(source).to have_slot(1, at: "0.statements.2.statements.1.expression")
        expect(source).to have_slot(1, at: "0.statements.4.expression")
      end

      specify "function variables are on the stack" do
        source = <<-LOX
          fun fn() {
            var x;
            var y;
          }
        LOX

        expect(source).to have_slot(0, at: "0.body.0")
        expect(source).to have_slot(1, at: "0.body.1")
      end

      xspecify "function parameters are on the stack" do
        source = <<-LOX
          fun fn(x, y) {
            var z;
          }
        LOX

        expect(source).to have_slot(0, at: "0.parameters.0")
        expect(source).to have_slot(1, at: "0.parameters.1")

        expect(source).to have_slot(2, at: "0.body.0")
      end

    #   it "works for multiple functions" do
    #     source = <<-LOX
    #       fun fn1() {
    #         var x = 1;
    #       }

    #       fun fn2() {
    #         var x = 1;

    #         {
    #           var y = 2;
    #           print y;
    #         }

    #         var z = 3;

    #         print x;
    #         print z;
    #       }
    #     LOX

    #     ast = resolve(source)

    #     expect(ast[1].body[0].allocation.slot).to eq(0)

    #     expect(ast[1].body[1].statements[0].allocation.slot).to eq(1)
    #     expect(ast[1].body[1].statements[1].expression.allocation.slot).to eq(1)

    #     expect(ast[1].body[2].allocation.slot).to eq(1)
    #     expect(ast[1].body[3].expression.allocation.slot).to eq(0)
    #     expect(ast[1].body[4].expression.allocation.slot).to eq(1)
    #   end

    #   it "assigns correct stack slots to local variables in blocks not taking into account upvalues" do
    #     source = <<-LOX
    #       fun fn() {
    #         var x = 1;

    #         {
    #           var y = 2;
    #           print y;
    #         }

    #         var z = 3;

    #         print x;
    #         print z;

    #         fun inner() {
    #           print x;
    #         }

    #         var after_fn = 4;
    #       }
    #     LOX

    #     ast = resolve(source)

    #     expect(ast[0].body[0].allocation).to be_heap_allocated

    #     expect(ast[0].body[1].statements[0].allocation.slot).to eq(0)
    #     expect(ast[0].body[1].statements[1].expression.allocation.slot).to eq(0)

    #     expect(ast[0].body[2].allocation.slot).to eq(0)
    #     expect(ast[0].body[3].expression.allocation).to be_heap_allocated

    #     expect(ast[0].body[6].allocation.slot).to eq(2)
    #   end

    #   it "assigns full name to functions" do
    #     source = <<-LOX
    #       fun outer() {
    #         fun inner() {
    #           print x;
    #         }
    #       }
    #     LOX

    #     ast = resolve(source)

    #     expect(ast[0].full_name).to eq("__global__outer__")
    #     expect(ast[0].body[0].full_name).to eq("__global__outer__inner__")
    #   end
    # end

    # RSpec.describe Phase1 do
    #   def resolve(source)
    #     tokens = Scanner.new(source).scan
    #     ast = Parser.new(tokens).parse

    #     resolver = StaticResolver::Phase1.new(error_reporter: self)
    #     resolver.resolve(ast)

    #     ast
    #   end

    #   it "infers global allocation to top level variables" do
    #     source = <<-LOX
    #       var x = 1;
    #     LOX

    #     ast = resolve(source)

    #     expect(ast[0].allocation).to be_global
    #   end

    #   it "infers local allocation to variables in function" do
    #     source = <<-LOX
    #       fun fn() {
    #         var x = 1;
    #         print x;

    #         {
    #           var y = 4;
    #           print y;
    #         }
    #       }
    #     LOX

    #     ast = resolve(source)

    #     expect(ast.first.body[0].allocation).to be_local
    #     expect(ast.first.body[1].expression.allocation).to be_local

    #     expect(ast.first.body[2].statements[0].allocation).to be_local
    #     expect(ast.first.body[2].statements[1].expression.allocation).to be_local
    #   end


    #   it "handles mixed" do
    #     source = <<-LOX
    #       var x = 1;
    #       print x;
    #       {
    #         var y = 2;
    #         print y;
    #       }
    #       var z = 3;
    #       print z;
    #     LOX

    #     ast = resolve(source)

    #     expect(ast[0].allocation).to be_global
    #     expect(ast[1].expression.allocation).to be_global

    #     expect(ast[2].statements[0].allocation).to be_local
    #     expect(ast[2].statements[1].expression.allocation).to be_local

    #     expect(ast[3].allocation).to be_global
    #     expect(ast[4].expression.allocation).to be_global
    #   end

    #   it "infers heap allocations" do
    #     source = <<-LOX
    #       fun fn() {
    #         var x = 1;
    #         var y = 2;
    #         print x;

    #         fun inner() {
    #           print x;
    #         }
    #       }
    #     LOX

    #     ast = resolve(source)

    #     expect(ast.first.body[0].allocation).to be_heap_allocated
    #     expect(ast.first.body[1].allocation).to be_local
    #     expect(ast.first.body[2].expression.allocation).to be_heap_allocated
    #     expect(ast.first.body[3].body.first.expression.allocation).to be_heap_allocated
    #   end

    #   it "does not confuse globals with heap allocated" do
    #     source = <<-LOX
    #       var x = 42;

    #       fun fn() {
    #         print x;
    #       }
    #     LOX

    #     ast = resolve(source)

    #     expect(ast.first.allocation).to be_global
    #     expect(ast[1].body.first.expression.allocation).to be_global
    #   end

    #   it "handles deep closures" do
    #     source = <<-LOX
    #       fun outer() {
    #         var outer_x = 1;
    #         var outer_y = 2;

    #         fun middle() {
    #           var middle_x = 3;
    #           var middle_y = 4;

    #           print outer_x;

    #           fun inner() {
    #             var inner_x = 5;
    #             print outer_x;
    #             print middle_x;
    #           }
    #         }
    #       }
    #     LOX

    #     ast = resolve(source)

    #     expect(ast.first.body[0].allocation).to be_heap_allocated
    #     expect(ast.first.body[1].allocation).to be_local

    #     expect(ast.first.body[2].body[0].allocation).to be_heap_allocated
    #     expect(ast.first.body[2].body[1].allocation).to be_local
    #     expect(ast.first.body[2].body[2].expression.allocation).to be_heap_allocated

    #     expect(ast.first.body[2].body[3].body[0].allocation).to be_local
    #     expect(ast.first.body[2].body[3].body[1].expression.allocation).to be_heap_allocated
    #     expect(ast.first.body[2].body[3].body[2].expression.allocation).to be_heap_allocated

    #     expect(ast.first.body[0].allocation).to equal(ast.first.body[2].body[3].body[1].expression.allocation)
    #   end
    end
  end
end
