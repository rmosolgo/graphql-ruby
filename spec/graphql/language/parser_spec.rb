require "spec_helper"

describe GraphQL::Language::Parser do
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
          assert_equal "NestedType", fragment.type.name
          assert_equal 1, fragment.directives.length
          assert_equal [2, 7], fragment.position
        end
      end

      it "parses the test schema" do
        schema = DummySchema
        schema_string = GraphQL::Schema::Printer.print_schema(schema)

        document = subject.parse(schema_string)

        assert_equal schema_string, document.to_query_string
      end
    end
  end
end
