# frozen_string_literal: true
module GraphQL
  class Schema
    class Union < GraphQL::Schema::Member
      def initialize(obj, ctx)
        @object = obj
        @context = ctx
      end

      class << self
        def possible_types(*types)
          if types.any?
            @own_possible_types = types
          else
            all_possible_types = own_possible_types
            inherited_possible_types = (superclass < GraphQL::Schema::Union ? superclass.possible_types : [])
            all_possible_types += inherited_possible_types
            all_possible_types.uniq
          end
        end

        def own_possible_types
          @own_possible_types ||= []
        end

        # The class resolves type by:
        # - make an instance
        # - call the instance method
        def resolve_type(value, ctx)
          self.new(value, ctx).resolve_type
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
