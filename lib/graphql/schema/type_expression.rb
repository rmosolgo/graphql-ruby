# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  class Schema
    module TypeExpression # :nodoc:
      # Fetch a type from a type map by its AST specification.
      # Return `nil` if not found.
      #
      # **Parameters**
      #
      # - `type_owner` (`#type`) — A thing for looking up types by name
      # - `ast_node` (`GraphQL::Language::Nodes::AbstractNode`)
      #
      # **Returns**
      #
      # - `Class, GraphQL::Schema::NonNull, GraphQL::Schema:List`
      #
      # :call-seq:
      #   build_type(#type type_owner, GraphQL::Language::Nodes::AbstractNode ast_node) -> Class | GraphQL::Schema::NonNull | GraphQL::Schema:List
      #: (GraphQL::Schema::Visibility::Profile | GraphQL::Schema::Warden::VisibilityProfile type_owner, GraphQL::Language::Nodes::AbstractNode ast_node) -> (GraphQL::Schema::Member::type_definition | GraphQL::Schema::NonNull | GraphQL::Schema::List | nil)
      def self.build_type(type_owner, ast_node)
        case ast_node
        when GraphQL::Language::Nodes::TypeName
          type_owner.type(ast_node.name) # rubocop:disable Development/ContextIsPassedCop -- this is a `context` or `warden`, it's already query-aware
        when GraphQL::Language::Nodes::NonNullType
          ast_inner_type = ast_node.of_type
          inner_type = build_type(type_owner, ast_inner_type)
          wrap_type(inner_type, :to_non_null_type)
        when GraphQL::Language::Nodes::ListType
          ast_inner_type = ast_node.of_type
          inner_type = build_type(type_owner, ast_inner_type)
          wrap_type(inner_type, :to_list_type)
        else
          raise "Invariant: unexpected type from ast: #{ast_node.inspect}"
        end
      end

      class << self
        private

        #: (GraphQL::Schema::Member::type_definition | GraphQL::Schema::NonNull | GraphQL::Schema::List | nil type, Symbol wrapper_method) -> (GraphQL::Schema::NonNull | GraphQL::Schema::List | nil)
        def wrap_type(type, wrapper_method)
          if type.nil?
            nil
          elsif wrapper_method == :to_list_type || wrapper_method == :to_non_null_type
            type.public_send(wrapper_method)
          else
            raise ArgumentError, "Unexpected wrapper method: #{wrapper_method.inspect}"
          end
        end
      end
    end
  end
end
