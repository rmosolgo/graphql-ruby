# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Visibility::Visit do
  describe "late-bound interfaces" do
    module VisitLateBoundInterfaces
      module Node
        include GraphQL::Schema::Interface
        field :id, ID
      end

      module Entity
        include GraphQL::Schema::Interface
        implements GraphQL::Schema::LateBoundType.new("Node")
        field :name, String
      end

      class Thing < GraphQL::Schema::Object
        implements GraphQL::Schema::LateBoundType.new("Entity")
      end

      # Don't add any types: Schema::Addition would try (and fail) to resolve the late-bound types eagerly
      class Schema < GraphQL::Schema
      end
    end

    it "resolves interfaces implemented by late-bound interfaces" do
      types = VisitLateBoundInterfaces
      visited = []
      visit = GraphQL::Schema::Visibility::Visit.new(types::Schema) { |m| visited << m; true }
      # LateBoundTypes are resolved from visited types, so they must be reachable some other way:
      visit.visit_each(types: [types::Thing, types::Entity, types::Node], directives: [])

      assert_includes visited, types::Entity
      assert_includes visited, types::Node
      assert_equal [types::Entity, types::Node], types::Thing.interfaces.sort_by(&:graphql_name)
      assert_equal [types::Node], types::Entity.interfaces
    end
  end
end
