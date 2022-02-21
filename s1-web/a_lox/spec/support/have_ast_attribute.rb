RSpec::Matchers.define :have_ast_attribute do |expected, at:|
  error = nil

  match do |ast|
    if ast
      current_node = ast

      at.split(".").each do |path_segment|
        current_node =
          if /\d+/.match?(path_segment)
            current_node[path_segment.to_i]
          else
            current_node.public_send(path_segment)
          end
      end

      if current_node != expected
        error = "Expected #{at} to have #{expected} but was #{current_node} instead"
        return false
      else
        return true
      end
    else
      return false
    end
  end

  failure_message do |actual|
    @compilation_error || error
  end
end
