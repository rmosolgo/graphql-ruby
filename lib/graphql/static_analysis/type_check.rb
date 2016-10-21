require "graphql/static_analysis/type_check/any_argument"
require "graphql/static_analysis/type_check/any_directive"
require "graphql/static_analysis/type_check/any_field"
require "graphql/static_analysis/type_check/any_input"
require "graphql/static_analysis/type_check/any_type"
require "graphql/static_analysis/type_check/any_type_kind"
require "graphql/static_analysis/type_check/required_arguments"
require "graphql/static_analysis/type_check/type_comparison"
require "graphql/static_analysis/type_check/type_condition"
require "graphql/static_analysis/type_check/valid_arguments"
require "graphql/static_analysis/type_check/valid_directives"
require "graphql/static_analysis/type_check/valid_literal"
require "graphql/static_analysis/type_check/valid_selections"
require "graphql/static_analysis/type_check/valid_variables"

module GraphQL
  module StaticAnalysis
    # This is responsible for several of the validations in the GraphQL spec:
    # - Field Selections on Objects, Interfaces, and Unions Types
    # - Field Selection Merging
    # - Leaf Field Selections
    # - Argument Names
    # - Argument Value Compatibility
    # - Required Arguments are Present
    # - Fragment Type Existence
    # - Fragments on Composite Types
    # - Fragment Spreads are Possible
    # - Object Spreads in Object Scope
    # - Abstract Spreads in Object Scope
    # - Object Spreads in Abstract Scope
    # - Abstract Spreads in Abstract Scope
    # - Directives are Defined
    # - Directives are in Valid Locations
    # - Variable Default Values are Correctly Typed
    # - Variables are Input Types
    # - Variable Usages are Allowed
    class TypeCheck
      include GraphQL::Language

      # @return [Array<GraphQL::StaticAnalysis::AnalysisError>] Errors found during typecheck
      attr_reader :errors

      attr_reader :schema

      def initialize(analysis)
        @analysis = analysis
        @schema = analysis.schema
        @errors = []
      end

      # Get a copy of the current trace for an error message
      def current_trace
        @analysis.trace.dup
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

        # Track fragment spreads, so that when you're done,
        # you can typecheck the spreads with their definitions
        # [Array<ObservedFragmentSpread>]
        observed_fragment_spreads = []

        # After you get the proper type for a fragment definition, stash it here
        # [Hash<String => GraphQL::BaseType>]
        fragment_definition_types = {}

        visitor[Nodes::OperationDefinition].enter << -> (node, prev_node) {
          # When you enter an operation definition:
          # - Check for the corresponding root type
          # - If it doesn't exist, push an error and choose AnyType
          # - Push the root type
          root_type = schema.root_type_for_operation(node.operation_type)
          if root_type.nil?
            errors << AnalysisError.new(
              %|"#{[node.operation_type, node.name].compact.join(" ")}" is invalid: root type "#{node.operation_type}" doesn't exist|,
              nodes: [node],
              fields: current_trace,
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
          observed_arguments = observed_arguments_stack.pop
          parent = type_stack.last
          err_msg = RequiredArguments.find_error(parent, field_defn, node, observed_arguments.map(&:name))
          if err_msg
            errors << AnalysisError.new(err_msg, nodes: [node], fields: current_trace)
          else
            # If they check out at the field level,
            # push 'em here for a more thorough check at the end of the run
            arguments_by_root[root_node].concat(observed_arguments)
          end
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

          argument_defn = parent.get_argument(node.name) || AnyArgument
          observed_argument = ObservedArgument.new(node: node, argument_defn: argument_defn, parent_defn: parent, trace: current_trace)
          # Push this argument here so we can check it later
          observed_arguments_stack.last << observed_argument
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
          observed_arguments = observed_arguments_stack.pop
          err_msg = RequiredArguments.find_error(nil, input_object_type, node, observed_arguments.map(&:name))
          if err_msg
            errors << AnalysisError.new(err_msg, nodes: [node], fields: current_trace)
          elsif field_stack.none?
            # If this is a variable default value,
            # it won't be validated by the parent field,
            # so push it here to make sure it's validated
            arguments_by_root[root_node].concat(observed_arguments)
          end
        }

        visitor[Nodes::InlineFragment].enter << -> (node, prev_node) {
          # There may be new type information
          if node.type
            next_type = schema.types.fetch(node.type, nil)
            owner_name = "inline fragment#{node.type ? " on \"#{node.type}\"" : ""}"
            type_errors = TypeCondition.errors_for_type_condition(node, next_type, owner_name)
            if type_errors.any?
              errors.concat(type_errors)
              next_type = AnyType
            else
              # This is the "parent" type, who _may_ receive this
              prev_type = type_stack.last
              spread_errors = TypeCondition.errors_for_spread(schema, prev_type, next_type, node, owner_name)
              if spread_errors.any?
                # This spread isn't valid, but let's keep validating.
                # It might be a typo, and we can still validate the children
                # of this spread, since we know what type it's for
                errors.concat(spread_errors)
              end
            end
          else
            # If the inline fragment doesn't have a type condition,
            # push the same type again
            next_type = type_stack.last
          end

          type_stack << next_type
        }

        visitor[Nodes::InlineFragment].leave << -> (node, prev_node) {
          # Either the type condition, or the same as the surrounding type
          type_stack.pop
        }

        visitor[Nodes::FragmentDefinition].enter << -> (node, prev_node) {
          owner_name = "fragment \"#{node.name}\""
          next_type = schema.types.fetch(node.type, nil)
          type_errors = TypeCondition.errors_for_type_condition(node, next_type, owner_name)
          if type_errors.any?
            errors.concat(type_errors)
            next_type = AnyType
          end

          fragment_definition_types[node.name] = next_type
          type_stack << next_type
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
          observed_arguments = observed_arguments_stack.pop
          err_msg = RequiredArguments.find_error(nil, current_directive_defn, node, observed_arguments.map(&:name))
          if err_msg
            errors << AnalysisError.new(err_msg, nodes: [node], fields: current_trace)
          else
            arguments_by_root[root_node].concat(observed_arguments)
          end
          current_directive_defn = nil
        }

        visitor[Nodes::FragmentSpread].enter << -> (node, prev_node) {
          observed_fragment_spreads << ObservedFragmentSpread.new(
            prev_type: type_stack.last,
            node: node,
          )
        }
        visitor[Nodes::Document].leave << -> (node, prev_node) {
          variables = @analysis.variable_usages
          dependencies = @analysis.dependencies
          variables.each do |op_defn, variable_data|
            variable_data[:defined].each do |variable_name, definitions|
              definitions.each do |defn_node|
                errors.concat(ValidVariables.definition_errors(variable_name, defn_node, schema))
              end
            end
          end

          arguments_by_root.each do |root_node, arguments|
            arguments.each do |observed_argument|
              errors.concat(ValidArguments.errors_for_argument(schema, variables, dependencies, root_node, observed_argument.parent_defn, observed_argument.argument_defn, observed_argument.node, observed_argument.trace))
            end
          end

          observed_fragment_spreads.each do |observed_fragment_spread|
            node_name = observed_fragment_spread.node.name
            frag_defn_type = fragment_definition_types[node_name]
            if frag_defn_type.nil?
              # Womp womp, this is an undefined fragment
            else
              owner_name = "\"...#{node_name}\""
              errors.concat(TypeCondition.errors_for_spread(schema, observed_fragment_spread.prev_type, frag_defn_type, node, owner_name))
            end
          end
        }
      end

      class ObservedFragmentSpread
        attr_reader :prev_type, :node
        def initialize(prev_type:, node:)
          @prev_type = prev_type
          @node = node
        end
      end

      class ObservedArgument
        attr_reader :node, :name, :argument_defn, :parent_defn, :trace
        def initialize(node:, argument_defn:, parent_defn:, trace:)
          @node = node
          @name = node.name
          @argument_defn = argument_defn
          @parent_defn = parent_defn
          @trace = trace
        end
      end
    end
  end
end
