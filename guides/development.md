---
layout: guide
search: true
title: Development
other: true
desc: Hacking on GraphQL Ruby
---

So, you want to hack on GraphQL Ruby! Here are some tips for getting started.

- [Setup](#setup) your development environment
- [Run the tests](#running-the-tests) to verify your setup
- [Debug](#debugging-with-pry) with pry
- [Run the benchmarks](#running-the-benchmarks) to test performance in your environment
- [Coding guidelines](#coding-guidelines) for working on your contribution
- Special tools for building the [lexer and parser](#lexer-and-parser)
- Building and publishing the [GraphQL Ruby website](#website)

### Setup

Get your own copy of graphql-ruby by forking [`rmosolgo/graphql-ruby` on GitHub](https://github.com/rmosolgo/graphql-ruby) and cloning your fork.

Then, install the dependencies:

- `bundle install`
- Optional: [Ragel 6.10](http://www.colm.net/open-source/ragel/) is required to build the lexer

### Running the Tests

You can run all the tests with

```
bundle exec rake        # tests & Rubocop
bundle exec rake test   # tests only
```

You can run a __specific file__ with `TEST=`:

```
bundle exec rake test TEST=spec/graphql/query_spec.rb
# run tests in `query_spec.rb` only
```

You can focus on a __specific example__ with `focus`:

```ruby
focus
it "does something cool" do
  # ...
end
```

Then, only `focus`ed tests will run:

```
bundle exec rake test
# only the focused test will be run
```

(This is provided by `minitest-focus`.)

You can __watch files__ with `guard`:

```
bundle exec guard
```

When a file in `lib/` is modified, `guard` will run the corresponding file in `spec`. Guard also respects `# test_via:` comments, so it will run that test when the file changes (if there is no corresponding file by name).

### Debugging with Pry

[`pry`](http://pryrepl.org/) is included with GraphQL-Ruby's development setup to help with debugging.

To pause execution in Ruby code, add:

```ruby
binding.pry
```

Then, the program will pause and your terminal will become a Ruby REPL. Feel free to use `pry` in your development process!

### Running the Benchmarks

This project includes some Rake tasks to record benchmarks:

```sh
$ bundle exec rake -T | grep bench:
rake bench:profile         # Generate a profile of the introspection query
rake bench:query           # Benchmark the introspection query
rake bench:validate        # Benchmark validation of several queries
```

You can save results by sending the output into a file:

```sh
$ bundle exec rake bench:validate > before.txt
$ cat before.txt
# ...
# --> benchmark output here
```

If you want to check performance, create a baseline by running these tasks before your changes. Then, make your changes and run the tasks again and compare your results.

Keep these points in mind when using benchmarks:

- The results are hardware-specific: computers with different hardware will have different results. So don't compare your results to results from other computers.
- The results are environment-specific: CPU and memory availability are affected by other processes on your computer. So try to create similar environments for your before-and-after testing.

### Coding Guidelines

GraphQL-Ruby uses a thorough test suite to make sure things work reliably day-after-day. Please include tests that describe your changes, for example:

- If you contribute a bug fix, include a test for the code that _was_ broken (and is now fixed)
- If you contribute a feature, include tests for all intended uses of that feature
- If you modify existing behavior, update the tests to cover all intended behaviors for that code

Don't fret about coding style or organization.  There's a minimal Rubocop config in `.rubocop.yml` which runs during CI. You can run it manually with `bundle exec rake rubocop`.

### Lexer and Parser

The lexer and parser use a multistep build process:

- Write the definition (`lexer.rl` or `parser.y`)
- Run the generator (Ragel or Racc) to create `.rb` files (`lexer.rb` or `parser.rb`)
- `require` those `.rb` files in GraphQL-Ruby

To update the lexer or parser, you should update their corresponding _definitions_ (`lexer.rl` or `parser.y`). Then, you can run `bundle exec build_parser` to re-generate the `.rb` files.

You will need Ragel to build the lexer (see above).

If you start __guard__ (`bundle exec guard`), the `.rb` files will be rebuilt whenever the definition files are modified.

### Website

To update the website, update the `.md` files in `guides/`.

To preview your changes, you can serve the website locally:

```
bundle exec rake site:serve
```

Then visit `http://localhost:4000`.

To publish the website with GitHub pages, run the Rake task:

```
bundle exec rake site:publish
```
