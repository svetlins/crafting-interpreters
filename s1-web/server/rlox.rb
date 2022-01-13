$LOAD_PATH.unshift File.join(__dir__, 'lib')

require 'scanner'
require 'expression'
require 'parser'
require 'static_resolver'
require 'interpreter'

require 'lab'
require 'printers/printer'
require 'readline'


class Rlox
  def initialize(argv)
    @argv = argv
    @had_error = false
    @vm = VM.new(error_reporter: self)
    @executable = Executable.new
  end

  def main
    if @argv.size > 2
      puts "Usage: rlox run [source_file] or rlox lab"
      exit(64)
    elsif @argv.size == 0
      run_prompt
    elsif @argv.first == 'run'
      run_file(@argv[1])
    elsif @argv.first == 'lab'
      Lab.run
    end
  end

  def run_file(file_name)
    run(File.read(file_name))
    exit(65) if @had_error
  end

  def run_prompt
    buffer = ""

    Readline.pre_input_hook = lambda do
       Readline.insert_text("  " * [buffer.count("{") - buffer.count("}"), 0].max)
       Readline.redisplay
    end

    while line = Readline.readline(buffer.empty? ? "> " : "| ", true)&.chomp
      if line.empty?
        execute(buffer)
        buffer = ""
      else
        buffer += line
      end
    end

    puts "👋"
  rescue Interrupt
    puts
    retry
  end

  def execute(source)
    @had_error = false

    tokens = Scanner.new(source, error_reporter: self).scan
    ast = Parser.new(tokens, error_reporter: self).parse

    return if @had_error

    phase1 = ::StaticResolver::Phase1.new(error_reporter: self)
    phase2 = ::StaticResolver::Phase2.new(error_reporter: self)
    phase1.resolve(ast)
    phase2.resolve(ast)

    return if @had_error

    Compiler.new(ast, @executable).compile

    return if @had_error

    @vm.execute(@executable)
  end

  def report_scanner_error(line, message)
    $stderr.puts "scanner error. line: #{line} - error: #{message}"
    @had_error = true
  end

  def report_parser_error(token, message)
    if token.type == TokenTypes::EOF
      $stderr.puts "parser error. line: #{token.line} at end - error: #{message}"
    else
      $stderr.puts "parser error. line: #{token.line}, token: #{token.lexeme} - error: #{message}"
    end

    @had_error = true
  end

  def report_static_analysis_error(token, message)
    $stderr.puts "static analysis error. line: #{token.line} - error: #{message}"
    @had_error = true
  end

  def report_runtime_error(message)
    $stderr.puts "runtime error: #{message}"
    @had_error = true
  end
end

Rlox.new(ARGV).main
