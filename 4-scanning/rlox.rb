$LOAD_PATH.unshift File.join(__dir__, 'lib')

require 'scanner'

class Rlox
  def initialize(argv)
    @argv = argv
    @@had_error = false
  end

  def main
    if @argv.size > 1
      puts "Usage: rlox [source_file]"
      exit(64)
    elsif @argv.size == 1
      run_file(@argv.first)
    else
      run_prompt
    end
  end

  def run_file(file_name)
    run(File.read(file_name))
    exit(65) if @@had_error
  end

  def run_prompt
    loop do
      print '> '
      line = $stdin.gets
      break if line.nil?
      run(line)
      @@had_error = false
    end
  end

  def run(source)
    scanner = Scanner.new(source)
    tokens = scanner.scan

    tokens.each do |token|
      p token
    end
  end

  def self.report_error(line, message)
    $stderr.puts "line: #{line} - error: #{message}"
    @@had_error = true
  end
end

Rlox.new(ARGV).main
