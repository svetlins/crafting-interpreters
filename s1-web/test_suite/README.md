This is a suite of some programs used to verify the behaviour of different implementations of a VM for the bytecode produced by my implementation of the Lox language. The idea is to have a form of a shared suite.

All examples are valid Lox code, and the expected behaviour is specified in comments looking like this `// => expected output`.

The `precompile.rb` script is used to produce compiled versions of each example in order to be able to validate implementations that only contain a VM (like the JS one at the moment)
