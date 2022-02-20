This is an implementation of (a subset of) the Lox language as described in [Crafting Interpreters](https://craftinginterpreters.com/). It is implemented in a slightly different approach by building on the tree-walker interpreter from the first part of the book but adding bytecode compilation and interpretation from the second part. The reason for this is entirely about me getting a better grasp at ideas which are more obscure when presented as part of a single-pass parser-compiler as is done in the second part of the book.

Currently there are also other notable changes:

- The bytecode opcode names have been changed
- Since both currently present VMs are written in garbage collected languages they don't implement the garbage collector described in the book

Additionally there's a web interface that provides an easy overview of the intermediate steps of compilation and step-by-step execution.

This repo contains:

- [A Ruby gem for the implementation of the language](a_lox/README.md)
- [A single-page application for the web interface](client/README.md)
  - [Demo](https://lox-analyzer.svetlins.net)
- [A bunch of annotated Lox programs used to verify different VMs](test_suite/README.md)

Currently there are two VMs: one in the Ruby gem and one in the web interface but my plan is to add other written in more-efficient languages as an exercise.
