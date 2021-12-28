require "spec_helper"

module StaticResolver
  RSpec.describe Phase1 do
    def resolve(source)
      tokens = Scanner.new(source).scan
      ast = Parser.new(tokens).parse

      resolver = ::StaticResolver::Phase1.new(error_reporter: self)
      resolver.resolve(ast)

      ast
    end

    it "infers global allocation to top level variables" do
      source = <<-LOX
        var x = 1;
      LOX

      ast = resolve(source)

      expect(ast[0].allocation).to be_global
    end

    it "infers local allocation to variables in function" do
      source = <<-LOX
        fun fn() {
          var x = 1;
          print x;

          {
            var y = 4;
            print y;
          }
        }
      LOX

      ast = resolve(source)

      expect(ast.first.body[0].allocation).to be_local
      expect(ast.first.body[1].expression.allocation).to be_local

      expect(ast.first.body[2].statements[0].allocation).to be_local
      expect(ast.first.body[2].statements[1].expression.allocation).to be_local
    end


    it "handles mixed" do
      source = <<-LOX
        var x = 1;
        print x;
        {
          var y = 2;
          print y;
        }
        var z = 3;
        print z;
      LOX

      ast = resolve(source)

      expect(ast[0].allocation).to be_global
      expect(ast[1].expression.allocation).to be_global

      expect(ast[2].statements[0].allocation).to be_local
      expect(ast[2].statements[1].expression.allocation).to be_local

      expect(ast[3].allocation).to be_global
      expect(ast[4].expression.allocation).to be_global
    end
  end
end
