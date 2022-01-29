# ALox

Ruby implemenation of (a subset of) the Lox language. This gem includes a parser, static analyzer, compiler and a VM, as well as a REPL tying them all together

## Installation

    $ gem install a_lox

## Usage

### As a library:

Make use of `ALox::Parser`, `ALox::StaticResolver::Phase1`, `ALox::StaticResolver::Phase2`, `ALox::Compiler`, `ALox::VM`. [Example code]](exe/alox)

### As a binary

```
alox # runs a REPL
alox file_name.lox # executes a Lox program
alox -c file_name.lox # outputs bytecode of a Lox program
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/a_lox. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/a_lox/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ALox project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/a_lox/blob/master/CODE_OF_CONDUCT.md).
