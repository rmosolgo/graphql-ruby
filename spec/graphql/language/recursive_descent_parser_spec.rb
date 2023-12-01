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

  it "parses the introspection query" do
    query_str = GraphQL::Introspection::INTROSPECTION_QUERY
    assert_equal(
      GraphQL.parse(query_str).to_query_string,
      subject.parse(query_str).to_query_string
    )
  end
  it "parses comments" do
    skip "TODO"
  end

  it "parses schemas" do
    schema_str = <<~GRAPHQL
    directive @stuff on FIELD

    schema {
      mutation: Blah
    }

    type Query implements Blah {
      f(a: Boolean = true): Int!
      f2(a: String = "abc"): String
    }

    interface Blah implements Foo & Bar {
      f2: Float!
    }

    union Thing = A | B

    input InputObj {
      in1: Int
    }

    enum Pet @stuff {
      CAT @thing
      DOG
      ROCK
    }

    scalar JSON

    extend scalar S @extended

    extend type T @extended

    extend interface I @extended

    extend union U @extended

    extend enum E @extended

    extend input IO @extended
    GRAPHQL

    assert_equal(
      schema_str,
      subject.parse(schema_str).to_query_string + "\n"
    )
  end

  it "parses some dummy schemas" do
    assert_equal Dummy::Schema.to_definition, subject.parse(Dummy::Schema.to_definition).to_query_string + "\n"
    assert_equal Jazz::Schema.to_definition, subject.parse(Jazz::Schema.to_definition).to_query_string + "\n"
  end
end
