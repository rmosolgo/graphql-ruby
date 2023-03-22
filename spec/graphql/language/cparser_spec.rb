# frozen_string_literal: true
require "spec_helper"
require "graphql/c_parser"

# TODO all parsing tests here
describe GraphQL::CParser::Parser do
  it "does something" do
    # pp GraphQL::Language::CParser.parse("{ }")
    pp GraphQL::CParser::Parser.parse("{ a b: c d(e: \"F\", g: HIJ, k: 1, l: 2.3, m: $M, n: null, o: { p: $Q }) }")
    # pp GraphQL::Language::CParser.parse("{ a @stuff(things: OK) }")
    # pp GraphQL::Language::CParser.parse("{ a { b c ... F } } fragment F on T { q }")

    # pp GraphQL::Language::CParser.parse("query { a b }")
  end
end
