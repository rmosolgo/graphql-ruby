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
  let(:hooks_counts) { {fields_entered: 0, arguments_entered: 0, arguments_left: 0, argument_names: []} }

  let(:hooks_visitor) do
    v = GraphQL::Language::Visitor.new(document)
    counts = hooks_counts
    v[GraphQL::Language::Nodes::Field] << ->(node, parent) { counts[:fields_entered] += 1 }
    # two ways to set up enter hooks:
    v[GraphQL::Language::Nodes::Argument] <<       ->(node, parent) { counts[:argument_names] << node.name }
    v[GraphQL::Language::Nodes::Argument].enter << ->(node, parent) { counts[:arguments_entered] += 1}
    v[GraphQL::Language::Nodes::Argument].leave << ->(node, parent) { counts[:arguments_left] += 1 }

    v[GraphQL::Language::Nodes::Document].leave << ->(node, parent) { counts[:finished] = true }
    v
  end

  class VisitorSpecVisitor < GraphQL::Language::Visitor
    attr_reader :counts
    def initialize(document)
      @counts = {fields_entered: 0, arguments_entered: 0, arguments_left: 0, argument_names: []}
      super
    end

    def on_field(node, parent)
      counts[:fields_entered] += 1
      super(node, parent)
    end

    def on_argument(node, parent)
      counts[:argument_names] << node.name
      counts[:arguments_entered] += 1
      super
    ensure
      counts[:arguments_left] += 1
    end

    def on_document(node, parent)
      counts[:finished] = true
      super
    end
  end

  class SkippingVisitor < VisitorSpecVisitor
    def on_document(_n, _p)
      SKIP
    end
  end

  let(:class_based_visitor) { VisitorSpecVisitor.new(document) }
  let(:class_based_counts) { class_based_visitor.counts }

  it "has an array of hooks" do
    assert_equal(2, hooks_visitor[GraphQL::Language::Nodes::Argument].enter.length)
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

  [:hooks, :class_based].each do |visitor_type|
    it "#{visitor_type} visitor calls hooks during a depth-first tree traversal" do
      visitor = public_send("#{visitor_type}_visitor")
      visitor.visit
      counts = public_send("#{visitor_type}_counts")
      assert_equal(6, counts[:fields_entered])
      assert_equal(2, counts[:arguments_entered])
      assert_equal(2, counts[:arguments_left])
      assert_equal(["id", "first"], counts[:argument_names])
      assert(counts[:finished])
    end

    describe "Visitor::SKIP" do
      let(:class_based_visitor) { SkippingVisitor.new(document) }

      it "#{visitor_type} visitor skips the rest of the node" do
        visitor = public_send("#{visitor_type}_visitor")
        if visitor_type == :hooks
          visitor[GraphQL::Language::Nodes::Document] << ->(node, parent) { GraphQL::Language::Visitor::SKIP }
        end
        visitor.visit
        counts = public_send("#{visitor_type}_counts")
        assert_equal(0, counts[:fields_entered])
      end
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

  describe "AST modification" do
    class ModificationTestVisitor < GraphQL::Language::Visitor
      def on_field(node, parent)
        if node.name == "c"
          new_node = node.merge(name: "renamedC")
          super(new_node, parent)
        elsif node.name == "addFields"
          new_node = node.merge_selection(name: "addedChild")
          super(new_node, parent)
        elsif node.name == "anotherAddition"
          new_node = node
            .merge_argument(name: "addedArgument", value: 1)
            .merge_directive(name: "doStuff")
          super(new_node, parent)
        else
          super
        end
      end

      def on_argument(node, parent)
        # https://github.com/rmosolgo/graphql-ruby/issues/2148
        # Parent could become a random value, double check that it's a node
        # to actually fail the test
        raise RuntimeError, "Parent isn't a Node!" unless parent.class < GraphQL::Language::Nodes::AbstractNode

        if node.name == "deleteMe"
          super(DELETE_NODE, parent)
        elsif node.name.include?("nope")
          [1]
        else
          super
        end
      end

      def on_variable_identifier(node, parent)
        if node.name == "firstName"
          node = node.merge(name: "lastName")
        end
        super(node, parent)
      end

      def on_input_object(node, parent)
        if node.arguments.map(&:name).sort == ["delete", "me"]
          super(DELETE_NODE, parent)
        else
          super
        end
      end

      def on_directive(node, parent)
        if node.name == "doStuff"
          new_node = node.merge_argument(name: "addedArgument2", value: 2)
          super(new_node, parent)
        else
          super
        end
      end

      def on_inline_fragment(node, parent)
        if node.selections.map(&:name) == ["renameFragmentField", "spread"]
          _field, spread = node.selections
          new_node = node.merge(selections: [GraphQL::Language::Nodes::Field.new(name: "renamed"), spread])
          super(new_node, parent)
        else
          super(node, parent)
        end
      end

      def on_fragment_spread(node, parent)
        if node.name == "spread"
          new_node = node.merge(name: "renamedSpread")
          super(new_node, parent)
        else
          super(node, parent)
        end
      end

      def on_object_type_definition(node, parent)
        if node.name == "Rename"
          new_node = node.merge(name: "WasRenamed")
          super(new_node, parent)
        else
          super(node, parent)
        end
      end

      def on_field_definition(node, parent)
        if node.name == "renameThis"
          new_node = node.merge(name: "wasRenamed")
          super(new_node, parent)
        else
          super
        end
      end

      def on_input_value_definition(node, parent)
        if node.name == "renameThisArg"
          new_node = node.merge(name: "argWasRenamed")
          super(new_node, parent)
        else
          super
        end
      end

      def on_variable_definition(node, parent)
        if node.type.name == 'A'
          new_type = GraphQL::Language::Nodes::TypeName.new(name: 'RenamedA')
          super(node.merge(type: new_type), parent)
        elsif node.name == "firstName"
          super(node.merge(name: "lastName"), parent)
        else
          super
        end
      end
    end

    def get_result(query_str)
      document = GraphQL.parse(query_str)
      visitor = ModificationTestVisitor.new(document)
      visitor.visit
      return document, visitor.result
    end

    it "can modify variable names" do
      query = <<-GRAPHQL.chop
query($firstName: String) {
  a(b: $firstName)
}
      GRAPHQL
      expected_result = <<-GRAPHQL.chop
query($lastName: String) {
  a(b: $lastName)
}
      GRAPHQL
      document, new_document = get_result(query)
      assert_equal expected_result, new_document.to_query_string, "the result has changes"
      assert_equal query, document.to_query_string, "the original is unchanged"
    end

    it "returns a new AST with modifications applied" do
      query = <<-GRAPHQL.chop
query($a: A, $b: B) {
  a(a1: 1) {
    b(b2: 2) {
      c(c3: 3)
    }
  }
  d(d4: 4)
}
      GRAPHQL
      document, new_document = get_result(query)
      refute_equal document, new_document
      expected_result = <<-GRAPHQL.chop
query($a: RenamedA, $b: B) {
  a(a1: 1) {
    b(b2: 2) {
      renamedC(c3: 3)
    }
  }
  d(d4: 4)
}
GRAPHQL
      assert_equal expected_result, new_document.to_query_string, "the result has changes"
      assert_equal query, document.to_query_string, "the original is unchanged"

      # This is testing the implementation: nodes which aren't affected by modification
      # should be shared between the two trees
      orig_c3_argument =     document.definitions.first.selections.first.selections.first.selections.first.arguments.first
      copy_c3_argument = new_document.definitions.first.selections.first.selections.first.selections.first.arguments.first
      assert_equal "c3", orig_c3_argument.name
      assert orig_c3_argument.equal?(copy_c3_argument), "Child nodes are persisted"

      orig_d_field =     document.definitions.first.selections[1]
      copy_d_field = new_document.definitions.first.selections[1]
      assert_equal "d", orig_d_field.name
      assert orig_d_field.equal?(copy_d_field), "Sibling nodes are persisted"

      orig_b_field =     document.definitions.first.selections.first.selections.first
      copy_b_field = new_document.definitions.first.selections.first.selections.first
      assert_equal "b", orig_b_field.name
      refute orig_b_field.equal?(copy_b_field), "Parents with modified children are copied"
    end

    it "deletes nodes with DELETE_NODE" do
      before_query = <<-GRAPHQL.chop
query {
  f1 {
    f2(deleteMe: 1) {
      f3(c1: {deleteMe: {c2: 2}})
      f4(c2: [{keepMe: 1}, {deleteMe: 2}, {keepMe: 3}])
    }
  }
}
GRAPHQL

      after_query = <<-GRAPHQL.chop
query {
  f1 {
    f2 {
      f3(c1: {})
      f4(c2: [{keepMe: 1}, {}, {keepMe: 3}])
    }
  }
}
GRAPHQL

      document, new_document = get_result(before_query)
      assert_equal before_query, document.to_query_string
      assert_equal after_query, new_document.to_query_string
    end

    it "Deletes from lists" do
      before_query = <<-GRAPHQL.chop
query {
  f1(arg1: [{a: 1}, {delete: 1, me: 2}, {b: 2}])
}
GRAPHQL

      after_query = <<-GRAPHQL.chop
query {
  f1(arg1: [{a: 1}, {b: 2}])
}
GRAPHQL

      document, new_document = get_result(before_query)
      assert_equal before_query, document.to_query_string
      assert_equal after_query, new_document.to_query_string
    end

    it "can add children" do
      before_query = <<-GRAPHQL.chop
query {
  addFields
  anotherAddition
}
GRAPHQL

      after_query = <<-GRAPHQL.chop
query {
  addFields {
    addedChild
  }
  anotherAddition(addedArgument: 1) @doStuff(addedArgument2: 2)
}
GRAPHQL

      document, new_document = get_result(before_query)
      assert_equal before_query, document.to_query_string
      assert_equal after_query, new_document.to_query_string
    end

    it "ignore non-Nodes::AbstractNode return values" do
      query = <<-GRAPHQL.chop
query {
  doesntDoAnything(stillNothing: {nope: 1, alsoNope: 2, stillNope: 3})
}
GRAPHQL

      document, new_document = get_result(query)
      assert_equal query, document.to_query_string
      assert_equal query, new_document.to_query_string
    end

    it "can modify inline fragments" do
      before_query = <<-GRAPHQL.chop
query {
  ... on Query {
    renameFragmentField
    ...spread
  }
}
GRAPHQL

      after_query = <<-GRAPHQL.chop
query {
  ... on Query {
    renamed
    ...renamedSpread
  }
}
GRAPHQL

      document, new_document = get_result(before_query)
      assert_equal before_query, document.to_query_string
      assert_equal after_query, new_document.to_query_string
    end

    it "works with SDL" do
      before_query = <<-GRAPHQL.chop
type Rename @doStuff {
  f: Int
  renameThis: String
  f2(renameThisArg: Boolean): Boolean
}
GRAPHQL

      after_query = <<-GRAPHQL.chop
type WasRenamed @doStuff(addedArgument2: 2) {
  f: Int
  wasRenamed: String
  f2(argWasRenamed: Boolean): Boolean
}
GRAPHQL

      document, new_document = get_result(before_query)
      assert_equal before_query, document.to_query_string
      assert_equal after_query, new_document.to_query_string
    end
  end
end
