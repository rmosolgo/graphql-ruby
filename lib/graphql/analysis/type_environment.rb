module GraphQL
  module Analysis
    # The first in the list of query reducers, this one
    # uses the provided {GraphQL::Schema} to add type information
    # to the reduction process. It is provided to each reducer
    # so that the reducer has access to the current type information
    # at each AST node.
    class TypeEnvironment
      include GraphQL::Language

      def initialize(schema)
        @schema = schema
        @type_definitions = []
        @field_definitions = []
        @directive_definitions = []
        @argument_definitions = []
      end

      # This field is where the next fields will be looked up (unless it's a scalar).
      # @return [GraphQL::BaseType] The type which was returned by the previous field
      def current_type_definition
        @type_definitions.last
      end

      # This is where the current field was looked up
      # @return [GraphQL::BaseType] The type which exposed the current field
      def parent_type_definition
        @type_definitions[-2]
      end

      # @return [GraphQL::Field] The definition of currently-entered field
      def current_field_definition
        @field_definitions.last
      end

      # @return [GraphQL::Directive] The definition of the currently-entered directive
      def current_directive_definition
        @directive_definitions.last
      end

      # @return [GraphQL::Argument] The definition of the currently-entered argument
      def current_argument_definition
        @argument_definitions.last
      end

      # @return [Proc] A {GraphQL::Analysis.reduce_query}-compliant call method for adding to the type environment
      def enter
        -> (memo, enter_or_leave, type_env_self, ast_node, prev_ast_node) {
         enter_or_leave == :enter && enter_node(ast_node)
        }
      end

      # @return [Proc] A {GraphQL::Analysis.reduce_query}-compliant call method for removing from the type environment
      def leave
        -> (memo, enter_or_leave, type_env_self, ast_node, prev_ast_node) {
         enter_or_leave == :leave && leave_node(ast_node)
        }
      end

      private

      def enter_node(ast_node)
        case ast_node
        when Nodes::InlineFragment, Nodes::FragmentDefinition
          object_type_defn = if ast_node.type
            @schema.types.fetch(ast_node.type, nil)
          else
            @type_definitions.last
          end
          if !object_type_defn.nil?
            object_type_defn = object_type_defn.unwrap
          end
          @type_definitions.push(object_type_defn)
        when Nodes::OperationDefinition
          object_type_defn = @schema.root_type_for_operation(ast_node.operation_type)
          @type_definitions.push(object_type_defn)
        when Nodes::Directive
          directive_defn = @schema.directives[ast_node.name]
          @directive_definitions.push(directive_defn)
        when Nodes::Field
          parent_type = @type_definitions.last
          if parent_type && parent_type.kind.fields?
            field_defn = @schema.get_field(parent_type, ast_node.name)
            @field_definitions.push(field_defn)
            next_object_type_defn = if field_defn.nil?
              nil
            else
              field_defn.type.unwrap
            end
            @type_definitions.push(next_object_type_defn)
          else
            @field_definitions.push(nil)
            @type_definitions.push(nil)
          end
        when Nodes::Argument
          # Argument lookup depends on where we are, it might be:
          # - inside another argument (nested input objects)
          # - inside a directive
          # - inside a field
          argument_defn = if @argument_definitions.last
            arg_type = @argument_definitions.last.type.unwrap
            if arg_type.kind.input_object?
              arg_type.input_fields[ast_node.name]
            else
              # This is a query error, a non-input-object has argument fields
              nil
            end
          elsif @directive_definitions.last
            @directive_definitions.last.arguments[ast_node.name]
          elsif @field_definitions.last
            @field_definitions.last.arguments[ast_node.name]
          else
            nil
          end
          @argument_definitions.push(argument_defn)
        else
          # This node doesn't add any information
          # to the the type environment
        end
      end

      def leave_node(ast_node)
        case ast_node
        when Nodes::InlineFragment, Nodes::FragmentDefinition, Nodes::OperationDefinition
          @type_definitions.pop
        when Nodes::Directive
          @directive_definitions.pop
        when Nodes::Field
          @field_definitions.pop
          @type_definitions.pop
        when Nodes::Argument
          @argument_definitions.pop
        else
          # This node didn't add anything to the stack(s),
          # so there's no need to remove anything
        end
      end
    end
  end
end
