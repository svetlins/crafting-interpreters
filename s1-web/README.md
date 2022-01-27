This is an implementation of (a subset of) the Lox language as described in [Crafting Interpreters](https://craftinginterpreters.com/). It is implemented in a slightly different approach by building on the tree-walker interpreter from the first part of the book but adding bytecode compilation and interpretation from the second part as additional steps. The reason for this is entirely about me getting a better grasp at ideas which are more obscure when presented as part of a single-pass parser-compiler as is done in the second part of the book.

Currently there are also other notable changes:

- The bytecode opcode names have been changed
- Closed-over variables are always allocated in the heap instead of represented as upvalues that are moved to the heap only when needed. The current approach is much more naive and will likely be changed to the one described in the book when I have time.
- Since both currently present VMs are written in garbage collected languages they don't implement the garbage collector described in the book

Additionally there's a web interface that provides an easy overview of the intermediate steps of compilation and step-by-step execution.

This repo contains:

- [A Ruby gem for the implementation of the language](a_lox/README.md)
- [A Sinatra API that wraps the compilation results in a web process](web/README.md)
- [A single-page application for the web interface](client/README.md)
  - [Demo](https://lox-analyzer.svetlins.net)
- [A bunch of annotated Lox programs used to verify different VMs](test_sutie/README.md)

Currently there are two VMs: one in the Ruby gem and one in the web interface but my plan is to add other as an exercize in more-efficient languages.
