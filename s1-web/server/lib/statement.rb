require 'ast_node_dsl'

module Statement
  include AstNodeDSL

  ExpressionStatement = define_node do
    expression
  end

  FunctionStatement = define_node do
    name
    parameters
    body
    additional :allocation, :full_name, :parameter_allocations, :heap_slots, :heap_usages
  end

  ReturnStatement = define_node do
    keyword
    value
  end

  PrintStatement = define_node { expression }

  VarStatement = define_node do
    name
    initializer
    additional :allocation
  end

  BlockStatement = define_node do
    statements
    additional :locals_count
  end

  IfStatement = define_node do
    condition
    then_branch
    else_branch
  end

  WhileStatement = define_node do
    condition
    body
  end

  ClassStatement = define_node do
    name
    superclass
    methods
  end
end
