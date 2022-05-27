require 'spec_helper'

module ALox
  RSpec.describe StaticResolver do
    def analyze(source)
      tokens = ALox::Scanner.new(source, error_reporter: self).scan
      ast = ALox::Parser.new(tokens, error_reporter: self).parse
      ALox::StaticResolver.new(error_reporter: self).resolve(ast)
      ast
    end

    it "does function top-level locals" do
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

      expect(ast).to have_ast_attribute(:global, at: '0.allocation.kind')

      expect(ast).to have_ast_attribute(:local, at: '1.body.0.allocation.kind')
      expect(ast).to have_ast_attribute(0, at: '1.body.0.allocation.slot')

      expect(ast).to have_ast_attribute(:local, at: '1.body.1.allocation.kind')
      expect(ast).to have_ast_attribute(1, at: '1.body.1.allocation.slot')

      expect(ast).to have_ast_attribute(:local, at: '1.body.2.expression.allocation.kind')
      expect(ast).to have_ast_attribute(0, at: '1.body.2.expression.allocation.slot')

      expect(ast).to have_ast_attribute(:local, at: '1.body.3.value.allocation.kind')
      expect(ast).to have_ast_attribute(1, at: '1.body.3.value.allocation.slot')
    end

    it 'does top level blocks' do
      source = <<-LOX
        var global = 1;

        {
          var x = 2;
          var y = 3;
        }
      LOX

      ast = analyze(source)

      expect(ast).to have_ast_attribute(:global, at: '0.allocation.kind')

      expect(ast).to have_ast_attribute(:local, at: '1.statements.0.allocation.kind')
      expect(ast).to have_ast_attribute(0, at: '1.statements.0.allocation.slot')

      expect(ast).to have_ast_attribute(2, at: '1.locals.count')
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

      expect(ast).to have_ast_attribute(:global, at: '0.allocation.kind')

      expect(ast).to have_ast_attribute(:local, at: '1.body.0.allocation.kind')
      expect(ast).to have_ast_attribute(0, at: '1.body.0.allocation.slot')

      expect(ast).to have_ast_attribute(:local, at: '1.body.1.statements.0.allocation.kind')
      expect(ast).to have_ast_attribute(1, at: '1.body.1.statements.0.allocation.slot')

      expect(ast).to have_ast_attribute(:local, at: '1.body.1.statements.1.allocation.kind')
      expect(ast).to have_ast_attribute(2, at: '1.body.1.statements.1.allocation.slot')

      expect(ast).to have_ast_attribute(:local, at: '1.body.2.allocation.kind')
      expect(ast).to have_ast_attribute(1, at: '1.body.2.allocation.slot')

      expect(ast).to have_ast_attribute(2, at: '1.body.1.locals.count')
    end

    it 'does upvalues' do
      source = <<-LOX
        fun outer() {
          var x = 1;

          fun inner() {
            print x;
          }
        }
      LOX

      ast = analyze(source)

      expect(ast).to have_ast_attribute(:local, at: '0.body.0.allocation.kind')
      expect(ast).to have_ast_attribute(true, at: '0.body.0.allocation.captured')
      expect(ast).to have_ast_attribute(:upvalue, at: '0.body.1.body.0.expression.allocation.kind')
      expect(ast).to have_ast_attribute(0, at: '0.body.1.body.0.expression.allocation.slot')
    end

    it 'does deep upvalues' do
      source = <<-LOX
        fun outer() {
          var x = 1;

          fun middle() {
            fun inner() {
              print x;
            }
          }
        }
      LOX

      ast = analyze(source)

      expect(ast).to have_ast_attribute(:local, at: '0.body.0.allocation.kind')
      expect(ast).to have_ast_attribute(true, at: '0.body.0.allocation.captured')
      expect(ast).to have_ast_attribute(:upvalue, at: '0.body.1.body.0.body.0.expression.allocation.kind')
      expect(ast).to have_ast_attribute(0, at: '0.body.1.body.0.body.0.expression.allocation.slot')

      expect(ast).to have_ast_attribute(true, at: '0.body.1.upvalues.0.local')
      expect(ast).to have_ast_attribute(false, at: '0.body.1.body.0.upvalues.0.local')

      expect(ast).to have_ast_attribute(true, at: '0.body.1.upvalues.0.local')
      expect(ast).to have_ast_attribute(false, at: '0.body.1.body.0.upvalues.0.local')
    end
  end
end
