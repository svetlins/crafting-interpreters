module ALox
  module Commands
    class ExecuteSource
      def self.call(source, executable: nil, vm: nil)
        new.call(source, executable, vm)
      end

      def call(source, executable, vm)
        executable ||= Executable.new

        @had_error = false

        tokens = Scanner.new(source, error_reporter: self).scan
        ast = Parser.new(tokens, error_reporter: self).parse

        return if @had_error

        phase1 = StaticResolver::Phase1.new(error_reporter: self)
        phase2 = StaticResolver::Phase2.new(error_reporter: self)
        phase1.resolve(ast)
        phase2.resolve(ast)

        return if @had_error

        Compiler.new(ast, executable).compile

        return if @had_error

        (vm || VM).execute(executable)
      end

      def report_scanner_error(line, message)
        warn "scanner error. line: #{line} - error: #{message}"
        @had_error = true
      end

      def report_parser_error(token, message)
        if token.type == TokenTypes::EOF
          warn "parser error. line: #{token.line} at end - error: #{message}"
        else
          warn "parser error. line: #{token.line}, token: #{token.lexeme} - error: #{message}"
        end

        @had_error = true
      end

      def report_static_analysis_error(token, message)
        warn "static analysis error. line: #{token.line} - error: #{message}"
        @had_error = true
      end

      def report_runtime_error(message)
        warn "runtime error: #{message}"
        @had_error = true
      end
    end
  end
end
