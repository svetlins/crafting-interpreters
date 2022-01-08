require 'ast_node_dsl'

module Expression
  include AstNodeDSL

  Assign = define_node do
    name
    value
    additional :allocation
  end

  Variable = define_node do
    name
    additional :allocation
  end

  Binary = define_node do
    left
    operator
    right
  end

  Logical = define_node do
    left
    operator
    right
  end

  Unary = define_node do
    operator
    right
  end

  Grouping = define_node { expression }

  Literal = define_node { value }

  Call = define_node do
    callee
    paren
    arguments
  end

  GetExpression = define_node do
    object
    name
  end

  SetExpression = define_node do
    object
    name
    value
  end

  SuperExpression = define_node do
    keyword
    method_name
  end

  ThisExpression = define_node { keyword }
end
