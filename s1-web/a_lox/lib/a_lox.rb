# frozen_string_literal: true

require_relative "a_lox/version"
require_relative "a_lox/printers/pretty_printer"
require_relative "a_lox/printers/tree_printer"
require_relative "a_lox/scanner"
require_relative "a_lox/ast_node_dsl"
require_relative "a_lox/expression"
require_relative "a_lox/statement"
require_relative "a_lox/parser"
require_relative "a_lox/static_resolver/phase1"
require_relative "a_lox/static_resolver/phase2"
require_relative "a_lox/executable"
require_relative "a_lox/compiler"
require_relative "a_lox/opcodes"
require_relative "a_lox/vm"

module ALox
  class Error < StandardError; end
end
