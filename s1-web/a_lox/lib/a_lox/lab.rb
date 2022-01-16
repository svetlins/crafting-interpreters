require "irb"

require "scanner"
require "expression"
require "parser"
require "printers/printer"
require "printers/sexp_printer"
require "printers/rpn_printer"
require "printers/tree_printer"
require "interpreter"
require "compiler"
require "vm"

module Lab
  include TokenTypes
  include Expression

  extend self

  def run
    IRB.setup nil
    IRB.conf[:MAIN_CONTEXT] = IRB::Irb.new.context
    require "irb/ext/multi-irb"
    IRB.irb nil, self
  end

  def generate_visitor(name)
    code =
      <<~RUBY.strip
        class #{name}Visitor
        ### Statements
        #{Statement.generate_visitors}
        
        ### Expressions
        #{Expression.generate_visitors}
        end
      RUBY

    puts code
  end

  def scan(source)
    Scanner.new(source, error_reporter: self).scan
  end

  def parse_tokens(tokens)
    Parser.new(tokens, error_reporter: self).parse
  end

  def parse(source)
    Parser.new(scan(source), error_reporter: self).parse
  end

  def compile_ast(ast)
    Compiler.new(ast).compile
  end

  def analyze(source)
    tokens = Scanner.new(source).scan
    ast = Parser.new(tokens).parse

    phase1 = ::StaticResolver::Phase1.new(error_reporter: self)
    phase2 = ::StaticResolver::Phase2.new(error_reporter: self)
    phase1.resolve(ast)
    phase2.resolve(ast)

    ast
  end

  def compile(source)
    tokens = Scanner.new(source).scan
    ast = Parser.new(tokens).parse
    executable = Executable.new

    phase1 = StaticResolver::Phase1.new(error_reporter: self)
    phase2 = StaticResolver::Phase2.new(error_reporter: self)
    phase1.resolve(ast)
    phase2.resolve(ast)

    Compiler.new(ast, executable).compile

    executable
  end

  def execute(executable)
    VM.execute(executable)
  end

  def interpret(source)
    Interpreter.new(
      error_reporter: self
    ).interpret(parse(source))
  end

  def report_scanner_error(line, message)
    pp ["scanner error", line, message]
  end

  def report_parser_error(token, message)
    pp ["parser error", token, message]
  end

  def report_runtime_error(token, message)
    pp ["interpreter error", token, message]
  end

  def sample_source0
    "var x = 1 + 2;"
  end

  def sample_source1
    "1 + 2 * 3;"
  end

  def sample_source2
    "(1 + 2) * 3;"
  end

  def sample_source3
    <<~CODE
      fun fn (a, b, c) {
        return a + b + c;
      }
    CODE
  end

  def malformed_source1
    "1 * (1 + 3;"
  end

  def sample_expression1
    Binary.new(
      Grouping.new(
        Binary.new(
          Literal.new(1),
          Token.new(TokenTypes::PLUS, "+", nil, 1),
          Literal.new(2)
        )
      ),
      Token.new(TokenTypes::STAR, "*", nil, 1),
      Grouping.new(
        Binary.new(
          Literal.new(4),
          Token.new(TokenTypes::MINUS, "-", nil, 1),
          Literal.new(3)
        )
      )
    )
  end
end
