require "spec_helper"
require 'graphql/language/parser_tests'

describe GraphQL::Language::Parser do
  include GraphQL::Language::ParserTests
  subject { GraphQL::Language::Parser }

  describe "anonymous fragment extension" do
    let(:document) { GraphQL.parse(query_string) }
    let(:query_string) {%|
      fragment on NestedType @or(something: "ok") {
        anotherNestedField
      }
    |}

    describe ".parse" do
      it "parses queries" do
        assert document
      end

      describe "visited nodes" do
        let(:fragment) { document.definitions.first }

        it "creates an anonymous fragment definition" do
          assert fragment.is_a?(GraphQL::Language::Nodes::FragmentDefinition)
          assert_equal nil, fragment.name
          assert_equal 1, fragment.selections.length
          assert_equal "NestedType", fragment.type
          assert_equal 1, fragment.directives.length
          assert_equal [2, 7], fragment.position
        end
      end
    end
  end
end
