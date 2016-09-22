require "graphql/static_analysis/type_check/any_argument"
require "graphql/static_analysis/type_check/any_field"
require "graphql/static_analysis/type_check/any_input"
require "graphql/static_analysis/type_check/any_type"
require "graphql/static_analysis/type_check/any_type_kind"
require "graphql/static_analysis/type_check/required_arguments"

module GraphQL
  module StaticAnalysis
    # This is responsible for several of the validations in the GraphQL spec:
    # - [ ] Field Selections on Objects, Interfaces, and Unions Types
    # - [ ] Field Selection Merging
    # - [ ] Leaf Field Selections
    # - [ ] Argument Names
    # - [ ] Argument Value Compatibility
    # - [ ] Required Arguments are Present
    # - [ ] Fragment Type Existence
    # - [ ] Fragments on Composite Types
    # - [ ] Fragment Spreads are Possible
    # - [ ] Object Spreads in Object Scope
    # - [ ] Abstract Spreads in Object Scope
    # - [ ] Object Spreads in Abstract Scope
    # - [ ] Abstract Spreads in Abstract Scope
    # - [ ] Directives are Defined
    # - [ ] Directives are in Valid Locations
    # - [ ] Variable Default Values are Correctly Typed
    # - [ ] Variables are Input Types
    # - [ ] Variable Usages are Allowed
    class TypeCheck
      include GraphQL::Language

      DYNAMIC_FIELD_PREFIX = "__"
      NO_ERRORS = []

      # @return [Array<GraphQL::StaticAnalysis::AnalysisError>] Errors found during typecheck
      attr_reader :errors

      attr_reader :schema

      def initialize(analysis)
        @analysis = analysis
        @schema = analysis.schema # TODO: or AnySchema
        @errors = []
      end

      def mount(visitor)
        # As we enter types via selections,
        # they'll be pushed on this array.
        # As we exit, they get popped off.
        # [Array<GraphQL::BaseType>]
        type_stack = []

        # This holds the fields you've entered
        # [Array<GraphQL::Field>]
        field_stack = []

        # When you enter a field, push an entry
        # on this list. Then on the way out,
        # make sure you weren't missing any required arguments.
        # [Array<Array<String>>]
        observed_arguments_stack = []

        # This tracks entered arguments.
        # You can get the last argument type for
        # nested input objects.
        # [Array<GraphQL::Argument>]
        argument_stack = []

        visitor[Nodes::OperationDefinition].enter << -> (node, prev_node) {
          # When you enter an operation definition:
          # - Check for the corresponding root type
          # - If it doesn't exist, push an error and choose AnyType
          # - Push the root type
          root_type = schema.root_type_for_operation(node.operation_type)
          if root_type.nil?
            errors << AnalysisError.new(
              %|Root type doesn't exist for operation: "#{node.operation_type}"|,
              nodes: [node]
            )
            root_type = AnyType
          end
          type_stack << root_type
        }

        visitor[Nodes::OperationDefinition].leave << -> (node, prev_node) {
          # Pop the root type
          type_stack.pop
        }

        visitor[Nodes::Field].enter << -> (node, prev_node) {
          # Find the field definition & field type and push them
          # If you can't find it, push AnyField instead
          parent_type = type_stack.last

          field_defn = schema.get_field(parent_type, node.name)
          if field_defn.nil?
            errors << AnalysisError.new(
              %|Field "#{node.name}" doesn't exist on "#{parent_type.name}"|,
              nodes: [node]
            )
            field_defn = AnyField
          end

          field_type = field_defn.type.unwrap
          field_selections = node.selections.select { |s| s.is_a?(Nodes::Field) }
          user_field_selections = field_selections.select { |s| !s.name.start_with?(DYNAMIC_FIELD_PREFIX) }
          field_type_kind = field_type.kind
          error_nodes = NO_ERRORS
          error_message = nil

          if !field_type_kind.composite? && node.selections.any?
            # It's a scalar with selections
            error_message = "can't have selections"
            error_nodes = node.selections
          elsif !field_type_kind.fields? && user_field_selections.any?
            # It's a union with direct selections
            error_message = "can't have direct selections, use a fragment spread to access members instead"
            error_nodes = user_field_selections
          elsif !field_type_kind.scalar? && node.selections.none?
            if field_type_kind.fields?
              # It's an object or interface with no selections
              error_message = "must have selections"
            else
              # It's a union with no selections
              error_message = "must have selections on a member type"
            end
            error_nodes = [node]
          end

          if error_message
            owner_name = "#{parent_type.name}.#{field_defn.name}"
            errors << AnalysisError.new(
            %|Type "#{field_type.name}" #{error_message}, see "#{owner_name}"|,
            nodes: error_nodes
            )
            # Stuff is about to get wacky, let's ignore it
            field_defn = AnyField
            field_type = field_defn.type
          end

          field_stack << field_defn
          type_stack << field_type
          observed_arguments_stack << []

        }

        visitor[Nodes::Field].leave << -> (node, prev_node) {
          # Pop the field's type & defn
          type_stack.pop
          field_defn = field_stack.pop
          observed_argument_names = observed_arguments_stack.pop
          parent = type_stack.last
          errors.concat(RequiredArguments.find_errors(parent, field_defn, node, observed_argument_names))
        }

        visitor[Nodes::Argument].enter << -> (node, prev_node) {
          # Get the corresponding argument defn for this node.
          # If there is one, mark it as observed
          # If there isn't one, get AnyArgument
          # Type-check its literal value or variable.

          # This could be an argument coming from any of these places:
          if argument_stack.any?
            parent = argument_stack.last.type.unwrap
          else
            parent = field_stack.last
          end

          argument_defn = parent.get_argument(node.name)

          if argument_defn.nil?
            case parent
            when GraphQL::Field
              # The _last_ one is the current field's type, so go back two
              # to get the parent object for that field:
              parent_type = type_stack[-2]
              parent_name = %|Field "#{parent_type.name}.#{parent.name}"|
            when GraphQL::InputObjectType
              parent_name = %|Input Object "#{parent.name}"|
            end
            errors << AnalysisError.new(
              %|#{parent_name} doesn't accept "#{node.name}" as an argument|,
              nodes: [node]
            )
            argument_defn = AnyArgument
          else
            observed_arguments_stack.last << argument_defn.name
            # TODO type-check argument
          end
          argument_stack << argument_defn
        }

        visitor[Nodes::Argument].leave << -> (node, prev_node) {
          # Remove yourself from the stack
          argument_stack.pop
        }

        visitor[Nodes::InputObject].enter << -> (node, prev_node) {
          # Prepare to validate required fields:
          observed_arguments_stack << []
          # Please excuse me while I borrow this:
          type_stack << argument_stack.last.type.unwrap
        }

        visitor[Nodes::InputObject].leave << -> (node, prev_node) {
          # pop yourself, and assert that your required fields were present
          input_object_type = type_stack.pop
          observed_argument_names = observed_arguments_stack.pop
          errors.concat(RequiredArguments.find_errors(nil, input_object_type, node, observed_argument_names))
        }

        visitor[Nodes::InlineFragment].enter << -> (node, prev_node) {
          # There may be new type information
          if node.type
            next_type = schema.types.fetch(node.type, nil)
            if next_type.nil?
              errors << AnalysisError.new(
                %|Type "#{node.type}" doesn't exist, so it can't be used as a fragment type|,
                nodes: [node]
              )
              next_type = AnyType
            end
            type_stack << next_type
          end
        }

        visitor[Nodes::InlineFragment].leave << -> (node, prev_node) {
          # If this node pushed a type, pop it
          if node.type
            type_stack.pop
          end
        }
      end
    end
  end
end
