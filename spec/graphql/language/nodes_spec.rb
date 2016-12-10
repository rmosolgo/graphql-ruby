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
end
