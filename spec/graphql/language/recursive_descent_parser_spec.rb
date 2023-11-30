# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Language::RecursiveDescentParser do
  let(:subject) { GraphQL::Language::RecursiveDescentParser }

  it "parses a document" do
    query_str = <<-GRAPHQL
      query DoStuff($a: Int) @a @b {
        a(b: [5, $a], c: {c2:  3.2}, d: "hi", e: BLAH, f: null)
        ... F
        ... on Query {
          c @if(blah: true, other: false)
        }
      }

      fragment F on Type { b }
    GRAPHQL
    assert_equal(
      GraphQL.parse(query_str).to_query_string,
      subject.parse(query_str).to_query_string
    )
  end
end
