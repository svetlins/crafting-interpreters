require "spec_helper"

RSpec.describe VM do
  specify do
    source = <<-LOX
      fun outer(p) {
        var x = p;

        fun middle() {
          fun inner() {
            print x * x * x;
          }

          return inner;
        }

        return middle;
      }

      var h1 = outer(2);
      var h2 = outer(3);

      h2()();
      h1()();
    LOX
  end
end
