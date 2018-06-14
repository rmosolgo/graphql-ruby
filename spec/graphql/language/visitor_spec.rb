# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Language::Visitor do
  let(:document) { GraphQL.parse("
    query cheese {
      cheese(id: 1) {
        flavor,
        source,
        producers(first: 3) {
          name
        }
        ... cheeseFields
      }
    }

    fragment cheeseFields on Cheese { flavor }
    ")}
  let(:counts) { {fields_entered: 0, arguments_entered: 0, arguments_left: 0, argument_names: []} }

  let(:visitor) do
    v = GraphQL::Language::Visitor.new(document)
    v[GraphQL::Language::Nodes::Field] << ->(node, parent) { counts[:fields_entered] += 1 }
    # two ways to set up enter hooks:
    v[GraphQL::Language::Nodes::Argument] <<       ->(node, parent) { counts[:argument_names] << node.name }
    v[GraphQL::Language::Nodes::Argument].enter << ->(node, parent) { counts[:arguments_entered] += 1}
    v[GraphQL::Language::Nodes::Argument].leave << ->(node, parent) { counts[:arguments_left] += 1 }

    v[GraphQL::Language::Nodes::Document].leave << ->(node, parent) { counts[:finished] = true }
    v
  end

  it "calls hooks during a depth-first tree traversal" do
    assert_equal(2, visitor[GraphQL::Language::Nodes::Argument].enter.length)
    visitor.visit
    assert_equal(6, counts[:fields_entered])
    assert_equal(2, counts[:arguments_entered])
    assert_equal(2, counts[:arguments_left])
    assert_equal(["id", "first"], counts[:argument_names])
    assert(counts[:finished])
  end

  it "can visit a document with directive definitions" do
    document = GraphQL.parse("
      # Marks an element of a GraphQL schema as only available via a preview header
      directive @preview(
        # The identifier of the API preview that toggles this field.
        toggledBy: String
      ) on SCALAR | OBJECT | FIELD_DEFINITION | ARGUMENT_DEFINITION | INTERFACE | UNION | ENUM | ENUM_VALUE | INPUT_OBJECT | INPUT_FIELD_DEFINITION

      type Query {
        hello: String
      }
    ")

    directive = nil
    directive_locations = []

    v = GraphQL::Language::Visitor.new(document)
    v[GraphQL::Language::Nodes::DirectiveDefinition] << ->(node, parent) { directive = node }
    v[GraphQL::Language::Nodes::DirectiveLocation] << ->(node, parent) { directive_locations << node }
    v.visit

    assert_equal "preview", directive.name
    assert_equal 10, directive_locations.length
  end

  describe "Visitor::SKIP" do
    it "skips the rest of the node" do
      visitor[GraphQL::Language::Nodes::Document] << ->(node, parent) { GraphQL::Language::Visitor::SKIP }
      visitor.visit
      assert_equal(0, counts[:fields_entered])
    end
  end

  it "can visit InputObjectTypeDefinition directives" do
    schema_sdl = <<-GRAPHQL
    input Test @directive {
      id: ID!
    }
    GRAPHQL

    document = GraphQL.parse(schema_sdl)

    visitor = GraphQL::Language::Visitor.new(document)

    visited_directive = false
    visitor[GraphQL::Language::Nodes::Directive] << ->(node, parent) { visited_directive = true }

    visitor.visit

    assert visited_directive
  end
end
