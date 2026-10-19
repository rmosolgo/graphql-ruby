# frozen_string_literal: true
# typed: true
module GraphQL
  module StaticValidation
    #--
    # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor
    module VariableUsagesAreAllowed
      # A variable in a fragment. It's checked after the visit, against each operation which uses the fragment.
      FragmentVariableUsage = Struct.new(:argument_owner, :arg_node, :variable_name, :path)

      def initialize(*)
        super
        # holds { name => ast_node } pairs
        @declared_variables = {}
        @operation_declared_variables = {}.compare_by_identity #: Hash[GraphQL::Language::Nodes::OperationDefinition, Hash[String, GraphQL::Language::Nodes::VariableDefinition]]
        @variable_usages_fragment_definition = nil
        @fragment_variable_usages = nil #: Hash[GraphQL::Language::Nodes::FragmentDefinition, Array[FragmentVariableUsage]]?
        @reported_fragment_variable_errors = nil #: Hash[GraphQL::Language::Nodes::Argument, Hash[String, bool]]?
      end

      def on_operation_definition(node, parent)
        @declared_variables = node.variables.each_with_object({}) { |var, memo| memo[var.name] = var }
        @operation_declared_variables[node] = @declared_variables
        super
      end

      def on_fragment_definition(node, parent)
        @variable_usages_fragment_definition = node
        super
        @variable_usages_fragment_definition = nil
      end

      def on_document(node, parent)
        super
        # A fragment can come before the operations which use it, and many operations can use it.
        # So, check its variable usages after the visit, against each operation which uses it.
        fragment_usages = @fragment_variable_usages
        return if fragment_usages.nil?

        dependencies = context.dependencies
        @operation_declared_variables.each do |definition, declared_variables|
          next if declared_variables.empty?

          checked_fragments = {}.compare_by_identity
          dependencies[definition].each do |fragment_definition|
            next if checked_fragments.key?(fragment_definition)
            checked_fragments[fragment_definition] = true
            usages = fragment_usages[fragment_definition]
            next if usages.nil?

            usages.each do |usage|
              var_defn_ast = declared_variables[usage.variable_name]
              # If it's undefined, VariablesAreUsedAndDefined adds an error
              var_defn_ast && validate_usage(usage.argument_owner, usage.arg_node, var_defn_ast, path: usage.path)
            end
          end
        end
      end

      def on_argument(node, parent)
        node_values = if node.value.is_a?(Array)
          node.value
        else
          [node.value]
        end
        node_values = node_values.select { |value| value.is_a? GraphQL::Language::Nodes::VariableIdentifier }

        if !node_values.empty?
          argument_owner = case parent
          when GraphQL::Language::Nodes::Field
            context.field_definition
          when GraphQL::Language::Nodes::Directive
            context.directive_definition
          when GraphQL::Language::Nodes::InputObject
            arg_type = context.argument_definition.type.unwrap
            if arg_type.kind.input_object?
              arg_type
            else
              # This is some kind of error
              nil
            end
          else
            raise("Unexpected argument parent: #{parent}")
          end

          if (fragment_definition = @variable_usages_fragment_definition)
            if argument_owner
              usages = ((@fragment_variable_usages ||= {}.compare_by_identity)[fragment_definition] ||= [])
              path = context.path
              node_values.each do |node_value|
                usages << FragmentVariableUsage.new(argument_owner, node, node_value.name, path)
              end
            end
          else
            node_values.each do |node_value|
              var_defn_ast = @declared_variables[node_value.name]
              # Might be undefined :(
              # VariablesAreUsedAndDefined can't finalize its search until the end of the document.
              var_defn_ast && argument_owner && validate_usage(argument_owner, node, var_defn_ast)
            end
          end
        end
        super
      end

      private

      #: (untyped argument_owner, GraphQL::Language::Nodes::Argument arg_node, GraphQL::Language::Nodes::VariableDefinition ast_var, ?path: Array[String]?) -> void
      def validate_usage(argument_owner, arg_node, ast_var, path: nil)
        var_type = context.schema.type_from_ast(ast_var.type, context: context)
        if var_type.nil?
          return
        end
        default_value = ast_var.default_value
        # An explicit `= null` default doesn't make the variable non-null
        if !default_value.nil? && !default_value.is_a?(GraphQL::Language::Nodes::NullValue)
          unless var_type.kind.non_null?
            # If the value is required, but the argument is not,
            # and yet there's a non-null default, then we impliclty
            # make the argument also a required type.
            var_type = var_type.to_non_null_type
          end
        end

        arg_defn = @types.argument(argument_owner, arg_node.name)
        arg_defn_type = arg_defn.type

        # If the argument is non-null, but it was given a default value,
        # then treat it as nullable in practice, see https://github.com/rmosolgo/graphql-ruby/issues/3793
        if arg_defn_type.non_null? && arg_defn.default_value?
          arg_defn_type = arg_defn_type.of_type
        end

        var_inner_type = var_type.unwrap
        arg_inner_type = arg_defn_type.unwrap

        var_type = wrap_var_type_with_depth_of_arg(var_type, arg_node)

        if var_inner_type != arg_inner_type
          create_error("Type mismatch", var_type, ast_var, arg_defn, arg_node, path)
        elsif list_dimension(var_type) != list_dimension(arg_defn_type)
          create_error("List dimension mismatch", var_type, ast_var, arg_defn, arg_node, path)
        elsif !non_null_levels_match(arg_defn_type, var_type)
          create_error("Nullability mismatch", var_type, ast_var, arg_defn, arg_node, path)
        end
      end

      #: (String error_message, untyped var_type, GraphQL::Language::Nodes::VariableDefinition ast_var, untyped arg_defn, GraphQL::Language::Nodes::Argument arg_node, Array[String]? path) -> void
      def create_error(error_message, var_type, ast_var, arg_defn, arg_node, path)
        message = "#{error_message} on variable $#{ast_var.name} and argument #{arg_node.name} (#{var_type.to_type_signature} / #{arg_defn.type.to_type_signature})"
        if path
          # Many operations can use one fragment, so add each error only once.
          reported = (@reported_fragment_variable_errors ||= {}.compare_by_identity)[arg_node] ||= {}
          return if reported.key?(message)
          reported[message] = true
        end

        add_error(GraphQL::StaticValidation::VariableUsagesAreAllowedError.new(
          message,
          nodes: arg_node,
          name: ast_var.name,
          type: var_type.to_type_signature,
          argument: arg_node.name,
          error: error_message
        ), path: path)
      end

      def wrap_var_type_with_depth_of_arg(var_type, arg_node)
        arg_node_value = arg_node.value
        return var_type unless arg_node_value.is_a?(Array)
        new_var_type = var_type

        depth_of_array(arg_node_value).times do
          # Since the array _is_ present, treat it like a non-null type
          # (It satisfies a non-null requirement AND a nullable requirement)
          new_var_type = new_var_type.to_list_type.to_non_null_type
        end

        new_var_type
      end

      # **Returns**
      #
      # - `Integer` — Returns the max depth of `array`, or `0` if it isn't an array at all
      #
      # :call-seq:
      #   depth_of_array(array) -> Integer
      def depth_of_array(array)
        case array
        when Array
          max_child_depth = 0 #: untyped
          array.each do |item|
            item_depth = depth_of_array(item)
            if item_depth > max_child_depth
              max_child_depth = item_depth
            end
          end
          1 + max_child_depth
        else
          0
        end
      end

      def list_dimension(type)
        if type.kind.list?
          1 + list_dimension(type.of_type)
        elsif type.kind.non_null?
          list_dimension(type.of_type)
        else
          0
        end
      end

      def non_null_levels_match(arg_type, var_type)
        if arg_type.kind.non_null? && !var_type.kind.non_null?
          false
        elsif arg_type.kind.wraps? && var_type.kind.wraps?
          # If var_type is a non-null wrapper for a type, and arg_type is nullable, peel off the wrapper
          # That way, a var_type of `[DairyAnimal]!` works with an arg_type of `[DairyAnimal]`
          if var_type.kind.non_null? && !arg_type.kind.non_null?
            var_type = var_type.of_type
          end
          non_null_levels_match(arg_type.of_type, var_type.of_type)
        else
          true
        end
      end
    end
  end
end
