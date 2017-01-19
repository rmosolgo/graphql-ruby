# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Language::Nodes::AbstractNode do
  describe "child and scalar attributes" do
    it "are inherited by node subclasses" do
      subclassed_directive = Class.new(GraphQL::Language::Nodes::Directive)

      assert_equal GraphQL::Language::Nodes::Directive.scalar_attributes,
        subclassed_directive.scalar_attributes

      assert_equal GraphQL::Language::Nodes::Directive.child_attributes,
        subclassed_directive.child_attributes
    end
  end

  describe "path" do
    let(:doc) { GraphQL.parse <<-GRAPHQL
      query DoSomeStuff($var: Int = 1) {
        ... on Stuff {
          innerField @someDirective(arg: { arg2: $var }) {
            ... thing
          }
        }
      }
      GRAPHQL
    }
    it "traces operations, fields, fragments, arguments, variables and directives" do
      definition = doc.definitions.first
      assert_equal("query DoSomeStuff", definition.path_key)
      assert_equal(["query DoSomeStuff"], definition.path)

      var = definition.variables.first
      assert_equal(["query DoSomeStuff", "$var"], var.path)

      inner_field = definition.selections.first.selections.first
      assert_equal(["query DoSomeStuff", "... on Stuff", "innerField"], inner_field.path)

      directive = inner_field.directives.first
      assert_equal(["query DoSomeStuff", "... on Stuff", "innerField", "@someDirective"], directive.path)
      arg = directive.arguments.first.value.arguments.first
      assert_equal(["query DoSomeStuff", "... on Stuff", "innerField", "@someDirective", "arg", "arg2"], arg.path)
      spread = inner_field.selections.first
      assert_equal(["query DoSomeStuff", "... on Stuff", "innerField", "... thing"], spread.path)
    end
  end
end
