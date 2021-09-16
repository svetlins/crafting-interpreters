$LOAD_PATH.unshift File.join(__dir__, 'lib')

require 'scanner'
require 'expression'
require 'parser'
require 'lab'
require 'printers/printer'

class Rlox
  def initialize(argv)
    @argv = argv
    @had_error = false
    @interpreter = Interpreter.new(error_reporter: self)
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
    loop do
      print '> '
      line = $stdin.gets
      break if line.nil?
      run(line)
      @had_error = false
    end
  end

  def run(source)
    scanner = Scanner.new(source, error_reporter: self)
    tokens = scanner.scan
    parser = Parser.new(tokens)
    expression = parser.parse
    value =

    if @had_error
      puts 'Aborting due to errors'
    else
      puts @interpreter.interpret(expression)
    end
  end

  def report_scanner_error(line, message)
    $stderr.puts "line: #{line} - error: #{message}"
    @had_error = true
  end

  def report_parser_error(token, message)
    if token.type == TokenTypes.EOF
      $stderr.puts "line: #{token.line} at end - error: #{message}"
    else
      $stderr.puts "line: #{token.line}, token: #{token.lexeme} - error: #{message}"
    end

    @had_error = true
  end

  def report_runtime_error(token, message)
    $stderr.puts "line: #{token.line} - error: #{message}"
    @had_error = true
  end
end

Rlox.new(ARGV).main
