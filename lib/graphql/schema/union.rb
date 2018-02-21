# frozen_string_literal: true
module GraphQL
  class Schema
    module Union
      extend ActiveSupport::Concern
      include GraphQL::Schema::Member
      extend GraphQL::Schema::Member::DSLMethods

      # TODO I think multiple-inherited Unions won't work yet.
      included do
        class << self
          def possible_types(*types)
            if types.any?
              @own_possible_types = types
            else
              all_possible_types = own_possible_types
              inherited_possible_types = (singleton_class < GraphQL::Schema::Union ? singleton_class.possible_types : [])
              all_possible_types += inherited_possible_types
              all_possible_types.uniq
            end
          end

          def own_possible_types
            @own_possible_types ||= []
          end

          def to_graphql
            type_defn = GraphQL::UnionType.new
            type_defn.name = graphql_name
            type_defn.description = description
            type_defn.possible_types = possible_types
            # If an instance method is defined, use it as a
            # resolve type hook, via the class method
            if method_defined?(:resolve_type)
              type_defn.resolve_type = method(:resolve_type)
            end
            type_defn
          end
        end
      end
    end
  end
end
