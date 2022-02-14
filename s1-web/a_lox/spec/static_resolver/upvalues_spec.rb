require 'spec_helper'

module ALox
  module StaticResolver
    RSpec.describe Upvalues do
      def analyze(source)
        tokens = ALox::Scanner.new(source, error_reporter: self).scan
        ast = ALox::Parser.new(tokens, error_reporter: self).parse
        ALox::StaticResolver::Upvalues.new(error_reporter: self).resolve(ast)
        ast
      end

      it "doesn't crash" do
        source = <<-LOX
          var global = 1;

          fun fn() {
            var x = 2;
            var y = 3;

            print x;

            return y;
          }

          fn();
        LOX

        ast = analyze(source)

        expect(ast).to have_ast_attribute2(:global, at: '0.allocation.kind')

        expect(ast).to have_ast_attribute2(:local, at: '1.body.0.allocation.kind')
        expect(ast).to have_ast_attribute2(0, at: '1.body.0.allocation.slot')

        expect(ast).to have_ast_attribute2(:local, at: '1.body.1.allocation.kind')
        expect(ast).to have_ast_attribute2(1, at: '1.body.1.allocation.slot')

        expect(ast).to have_ast_attribute2(:local, at: '1.body.2.expression.allocation.kind')
        expect(ast).to have_ast_attribute2(0, at: '1.body.2.expression.allocation.slot')

        expect(ast).to have_ast_attribute2(:local, at: '1.body.3.value.allocation.kind')
        expect(ast).to have_ast_attribute2(1, at: '1.body.3.value.allocation.slot')
      end

      it 'does top level blocks' do
        source = <<-LOX
          var global = 1;

          {
            var x = 2;
            var y = 3;
          }

          fn();
        LOX

        ast = analyze(source)

        expect(ast).to have_ast_attribute2(:global, at: '0.allocation.kind')

        expect(ast).to have_ast_attribute2(:local, at: '1.statements.0.allocation.kind')
        expect(ast).to have_ast_attribute2(0, at: '1.statements.0.allocation.slot')

        expect(ast).to have_ast_attribute2(2, at: '1.locals_count')
      end

      it 'does function blocks' do
        source = <<-LOX
          var global = 1;

          fun fn() {
            var x = 2;

            {
              var y = 3;
              var z = 4;
            }

            var zz = 5;
          }

          fn();
        LOX

        ast = analyze(source)

        expect(ast).to have_ast_attribute2(:global, at: '0.allocation.kind')

        expect(ast).to have_ast_attribute2(:local, at: '1.body.0.allocation.kind')
        expect(ast).to have_ast_attribute2(0, at: '1.body.0.allocation.slot')

        expect(ast).to have_ast_attribute2(:local, at: '1.body.1.statements.0.allocation.kind')
        expect(ast).to have_ast_attribute2(1, at: '1.body.1.statements.0.allocation.slot')

        expect(ast).to have_ast_attribute2(:local, at: '1.body.1.statements.1.allocation.kind')
        expect(ast).to have_ast_attribute2(2, at: '1.body.1.statements.1.allocation.slot')

        expect(ast).to have_ast_attribute2(:local, at: '1.body.2.allocation.kind')
        expect(ast).to have_ast_attribute2(1, at: '1.body.2.allocation.slot')

        expect(ast).to have_ast_attribute2(2, at: '1.body.1.locals_count')
      end
    end
  end
end
