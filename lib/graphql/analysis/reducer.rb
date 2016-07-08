module GraphQL
  module Analysis
    # A convenience for definining custom query reducers.
    #
    # You can override `initialize`, `before_` and/or `after_` hooks
    # to perform operations on certain kinds of nodes.
    #
    # To run something after reducing the whole query, implement `after_document`.
    #
    class Reducer
      include GraphQL::Language

      # These methods could be called for each visit_type + node class
      VISIT_METHODS = {
        enter: {
          Nodes::Document =>             :before_document,
          Nodes::Field =>                :before_field,
          Nodes::Directive =>            :before_directive,
          Nodes::Argument =>             :before_argument,
          Nodes::OperationDefinition =>  :before_operation_definition,
          Nodes::FragmentDefinition =>   :before_fragment_definition,
          Nodes::InlineFragment =>       :before_inline_fragment,
          Nodes::FragmentSpread =>       :before_fragment_spread,
          Nodes::Enum =>                 :before_enum,
          Nodes::InputObject =>          :before_input_object,
          Nodes::ListType =>             :before_list_type,
          Nodes::NonNullType =>          :before_non_null_type,
          Nodes::TypeName =>             :before_type_name,
          Nodes::VariableDefinition =>   :before_variable_definition,
          Nodes::VariableIdentifier =>   :before_variable_identifier,
        },
        leave: {
          Nodes::Document =>             :after_document,
          Nodes::Field =>                :after_field,
          Nodes::Directive =>            :after_directive,
          Nodes::Argument =>             :after_argument,
          Nodes::OperationDefinition =>  :after_operation_definition,
          Nodes::FragmentDefinition =>   :after_fragment_definition,
          Nodes::InlineFragment =>       :after_inline_fragment,
          Nodes::FragmentSpread =>       :after_fragment_spread,
          Nodes::Enum =>                 :after_enum,
          Nodes::InputObject =>          :after_input_object,
          Nodes::ListType =>             :after_list_type,
          Nodes::NonNullType =>          :after_non_null_type,
          Nodes::TypeName =>             :after_type_name,
          Nodes::VariableDefinition =>   :after_variable_definition,
          Nodes::VariableIdentifier =>   :after_variable_identifier,
        }
      }

      def call(memo, visit_type, type_env, ast_node, parent_ast_node)
        method_name = VISIT_METHODS[visit_type][ast_node.class]

        if respond_to?(method_name)
          self.public_send(method_name, memo, type_env, ast_node, parent_ast_node)
        else
          memo
        end
      end
    end
  end
end
