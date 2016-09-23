require "graphql/static_analysis/type_check/any_argument"
require "graphql/static_analysis/type_check/any_directive"
require "graphql/static_analysis/type_check/any_field"
require "graphql/static_analysis/type_check/any_input"
require "graphql/static_analysis/type_check/any_type"
require "graphql/static_analysis/type_check/any_type_kind"
require "graphql/static_analysis/type_check/required_arguments"
require "graphql/static_analysis/type_check/valid_arguments"
require "graphql/static_analysis/type_check/valid_directives"
require "graphql/static_analysis/type_check/valid_selections"

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

        # When you find an argument used by a root-level
        # node, push it here. We'll validate later
        # when we know all the dependencies
        # Each entry is `{node:, defn:, parent_defn:}`
        # [Hash<Definition => Array<Hash>>]
        arguments_by_root = Hash.new { |h, k| h[k] = [] }

        # Put the current root here, so we can figure out how arguments are used
        root_node = nil

        # Put the current directive here -- there can only ever be one
        current_directive_defn = nil

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
          root_node = node
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
          owner_name = %|"#{parent_type.name}.#{field_defn.name}"|
          selection_errors = ValidSelections.errors_for_selections(owner_name, field_type, node)
          if selection_errors.any?
            errors.concat(selection_errors)
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
          parent = if argument_stack.any?
            argument_stack.last.type.unwrap
          else
            current_directive_defn || field_stack.last
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
            when GraphQL::Directive
              parent_name = %|Directive "@#{parent.name}"|
            end
            errors << AnalysisError.new(
              %|#{parent_name} doesn't accept "#{node.name}" as an argument|,
              nodes: [node]
            )
            argument_defn = AnyArgument
          else
            observed_arguments_stack.last << argument_defn.name
          end
          # Push this argument here so we can check it later
          arguments_by_root[root_node] << {node: node, defn: argument_defn, parent_defn: parent}
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

          # Either the type from the condition, or the one from the surrounding selection
          parent_type = type_stack.last

          # If we failed to find a type, the parent type is AnyType,
          # so there won't be any errors and the typename won't show up
          owner_name = "inline fragment#{node.type ? " on \"#{node.type}\"" : ""}"
          selection_errors = ValidSelections.errors_for_selections(owner_name, parent_type, node)
          errors.concat(selection_errors)
        }

        visitor[Nodes::InlineFragment].leave << -> (node, prev_node) {
          # If this node pushed a type, pop it
          if node.type
            type_stack.pop
          end
        }

        visitor[Nodes::FragmentDefinition].enter << -> (node, prev_node) {
          next_type = schema.types.fetch(node.type, nil)
          if next_type.nil?
            errors << AnalysisError.new(
              %|Type "#{node.type}" doesn't exist, so it can't be used as a fragment type|,
              nodes: [node]
            )
            next_type = AnyType
          end
          type_stack << next_type

          owner_name = "fragment \"#{node.name}\""
          selection_errors = ValidSelections.errors_for_selections(owner_name, next_type, node)
          errors.concat(selection_errors)
          root_node = node
        }

        visitor[Nodes::FragmentDefinition].leave << -> (node, prev_node) {
          # Remove type condition
          type_stack.pop
        }

        visitor[Nodes::Directive].enter << -> (node, prev_node) {
          current_directive_defn = schema.directives[node.name]
          if current_directive_defn.nil?
            errors << AnalysisError.new(
              %|Directive "@#{node.name}" is not defined|,
              nodes: [node]
            )
            current_directive_defn = AnyDirective
          else
            errors.concat(ValidDirectives.location_errors(current_directive_defn, node, prev_node))
          end
          observed_arguments_stack << []
        }

        visitor[Nodes::Directive].leave << -> (node, prev_node) {
          current_directive_defn = nil
          observed_arguments_stack.pop
        }

        visitor[Nodes::Document].leave << -> (node, prev_node) {
          variables = @analysis.variable_usages
          arguments_by_root.each do |root_node, arguments|
            arguments.each do |argument|
              errors.concat(ValidArguments.errors_for_argument(variables, root_node, argument[:parent_defn], argument[:defn], argument[:node]))
            end
          end
        }
      end
    end
  end
end
