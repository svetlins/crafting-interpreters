module ALox
  module TokenTypes
    LEFT_PAREN = "LEFT_PAREN"
    RIGHT_PAREN = "RIGHT_PAREN"
    LEFT_BRACE = "LEFT_BRACE"
    RIGHT_BRACE = "RIGHT_BRACE"
    COMMA = "COMMA"
    DOT = "DOT"
    MINUS = "MINUS"
    PLUS = "PLUS"
    SEMICOLON = "SEMICOLON"
    SLASH = "SLASH"
    STAR = "STAR"

    BANG = "BANG"
    BANG_EQUAL = "BANG_EQUAL"
    EQUAL = "EQUAL"
    EQUAL_EQUAL = "EQUAL_EQUAL"

    GREATER = "GREATER"
    GREATER_EQUAL = "GREATER_EQUAL"
    LESS = "LESS"
    LESS_EQUAL = "LESS_EQUAL"

    IDENTIFIER = "IDENTIFIER"
    STRING = "STRING"
    NUMBER = "NUMBER"

    AND = "AND"
    ELSE = "ELSE"
    FALSE = "FALSE"
    FUN = "FUN"
    FOR = "FOR"
    IF = "IF"
    NIL = "NIL"
    OR = "OR"

    PRINT = "PRINT"
    RETURN = "RETURN"
    TRUE = "TRUE"
    VAR = "VAR"
    WHILE = "WHILE"

    EOF = "EOF"
  end

  Token = Struct.new(:type, :lexeme, :literal, :line) do
    def as_json
      to_h.merge(name: "TOKEN")
    end
  end

  class Scanner
    include TokenTypes

    KEY_WORDS = {
      "and" => AND,
      "else" => ELSE,
      "false" => false,
      "for" => FOR,
      "fun" => FUN,
      "if" => IF,
      "nil" => nil,
      "or" => OR,
      "print" => PRINT,
      "return" => RETURN,
      "true" => true,
      "var" => VAR,
      "while" => WHILE
    }

    def initialize(source, error_reporter: nil)
      @source = source
      @tokens = []

      @start = 0
      @current = 0
      @line = 1

      @error_reporter = error_reporter
    end

    def scan
      while has_more?
        @start = @current
        scan_token
      end

      @start = @current

      add_token(EOF)

      @tokens
    end

    def scan_token
      current_char = advance

      case current_char
      when "(" then add_token(LEFT_PAREN)
      when ")" then add_token(RIGHT_PAREN)
      when "{" then add_token(LEFT_BRACE)
      when "}" then add_token(RIGHT_BRACE)
      when "," then add_token(COMMA)
      when "." then add_token(DOT)
      when "-" then add_token(MINUS)
      when "+" then add_token(PLUS)
      when ";" then add_token(SEMICOLON)
      when "*" then add_token(STAR)
      when "!" then add_token(match?("=") ? BANG_EQUAL : BANG)
      when "=" then add_token(match?("=") ? EQUAL_EQUAL : EQUAL)
      when "<" then add_token(match?("=") ? LESS_EQUAL : LESS)
      when ">" then add_token(match?("=") ? GREATER_EQUAL : GREATER)
      when "/"
        if match?("/")
          while peek != "\n" && has_more?
            advance
          end
        else
          add_token(SLASH)
        end
      when "\n" then @line += 1
      when /\s/ then noop
      when '"' then consume_string
      when /\d/ then consume_number
      when /\w/ then consume_identifier
      else
        @error_reporter.report_scanner_error(@line, "invalid token")
      end
    end

    def noop
    end

    def at_end?
      @current >= @source.size
    end

    def has_more?
      !at_end?
    end

    def advance
      char = @source[@current]
      @current += 1
      char
    end

    def peek
      return "\0" if at_end?
      @source[@current]
    end

    def peek_next
      return "\0" if at_end?
      @source[@current + 1]
    end

    def match?(expected)
      return false if at_end?
      return false if @source[@current] != expected

      @current += 1

      true
    end

    def consume_string
      while peek != '"' && has_more?
        @line += 1 if peek == "\n"
        advance
      end

      if at_end?
        @error_reporter.report_scanner_error(@line, "unterminated string")
      end

      advance # closing "

      add_token(STRING, @source[@start + 1...@current - 1])
    end

    def consume_number
      while digit?(peek)
        advance
      end

      if peek == "." && digit?(peek_next)
        advance

        while digit?(peek)
          advance
        end
      end

      add_token(NUMBER, @source[@start...@current].to_f)
    end

    def consume_identifier
      while peek =~ /\w/
        advance
      end

      lexeme = @source[@start...@current]

      add_token(KEY_WORDS[lexeme] || IDENTIFIER)
    end

    def digit?(char)
      char >= "0" && char <= "9"
    end

    def add_token(type, literal = nil)
      lexeme = @source[@start...@current]
      @tokens << Token.new(type, lexeme, literal, @line)
    end
  end
end
