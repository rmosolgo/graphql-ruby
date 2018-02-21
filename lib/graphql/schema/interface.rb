# frozen_string_literal: true
module GraphQL
  class Schema
    module Interface
      extend ActiveSupport::Concern
      include GraphQL::Schema::Member
      include GraphQL::Schema::Member::HasFields

      included do
        class << self
          def apply_implemented(object_class)
            object_class.include(self)
          end

          def to_graphql
            type_defn = GraphQL::InterfaceType.new
            type_defn.name = graphql_name
            type_defn.description = description
            fields.each do |field_name, field_inst|
              field_defn = field_inst.graphql_definition
              type_defn.fields[field_defn.name] = field_defn
            end
            type_defn
          end

          # Here's the tricky part. Make sure behavior keeps making its way down the inheritance chain.
          def append_features(child_class)
            if !child_class.is_a?(Class)
              child_class.include(GraphQL::Schema::Interface)
              child_class.extend(GraphQL::Schema::Member::DSLMethods)
            end

            super
          end
        end
      end
    end
  end
end
