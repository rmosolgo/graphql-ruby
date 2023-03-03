# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Language::CParser do
  it "does something" do
    pp GraphQL::Language::CParser.parse("{ }")
    pp GraphQL::Language::CParser.parse("{ a b: c d(e: \"F\", g: HIJ, k: 1, l: 2.3) }")
    pp GraphQL::Language::CParser.parse("{ a @stuff(things: OK) }")
    pp GraphQL::Language::CParser.parse("{ a { b c } }")

    # pp GraphQL::Language::CParser.parse("query { a b }")
  end
end
