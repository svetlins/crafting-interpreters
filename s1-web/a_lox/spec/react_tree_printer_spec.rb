require 'spec_helper'

module ALox
  RSpec.describe Printers::ReactTreePrinter do
    it "works" do
      source = <<-LOX
        fun fn() {
          var x = 42;

          fun inner() {
            if (true) {
              print x; // => 42.0
            }
          }

          return inner;
        }

        var closure = fn();
        closure();
      LOX

      tokens = Scanner.new(source, error_reporter: self).scan
      ast = Parser.new(tokens, error_reporter: self).parse
      StaticResolver::Upvalues.new.resolve(ast)

      expect do
        Printers::ReactTreePrinter.new(ast).print
      end.not_to raise_error
    end
  end
end
