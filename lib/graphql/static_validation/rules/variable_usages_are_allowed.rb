# frozen_string_literal: true
# typed: true
module GraphQL
  module StaticValidation
    #--
    # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor
    module VariableUsagesAreAllowed
      # A variable in a fragment. It's checked after the visit, against each operation which uses the fragment.
      # `list_depth` is the number of list literals around the variable.
      FragmentVariableUsage = Struct.new(:argument_owner, :arg_node, :variable_name, :list_depth, :path, :checked_variable_types)

      def initialize(*)
        super
        # holds { name => ast_node } pairs
        @declared_variables = {}
        @operation_declared_variables = {}.compare_by_identity #: Hash[GraphQL::Language::Nodes::OperationDefinition, Hash[String, GraphQL::Language::Nodes::VariableDefinition]]
        @variable_usages_fragment_definition = nil
        @fragment_variable_usages = nil #: Hash[GraphQL::Language::Nodes::FragmentDefinition, Array[FragmentVariableUsage]]?
        @reported_fragment_variable_errors = nil #: Hash[GraphQL::Language::Nodes::Argument, Hash[String, bool]]?
        @allow_legacy_invalid_variable_usages = @schema.allow_legacy_invalid_variable_usages
        # The arguments and variables which have an error from the legacy check
        @legacy_errors = nil #: Hash[GraphQL::Language::Nodes::Argument, Hash[String, bool]]?
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

          variable_types = {} #: Hash[String, untyped]
          checked_fragments = {}.compare_by_identity
          dependencies[definition].each do |fragment_definition|
            next if checked_fragments.key?(fragment_definition)
            checked_fragments[fragment_definition] = true
            usages = fragment_usages[fragment_definition]
            next if usages.nil?

            usages.each do |usage|
              var_defn_ast = declared_variables[usage.variable_name]
              # If it's undefined, VariablesAreUsedAndDefined adds an error
              next if var_defn_ast.nil?
              var_type = variable_types.fetch(usage.variable_name) { variable_types[usage.variable_name] = usage_variable_type(var_defn_ast) }
              next if var_type.nil?
              # The result depends only on the usage and the variable type, so check each pair once.
              # (`type_from_ast` returns the same object for the same type.)
              checked = (usage.checked_variable_types ||= {}.compare_by_identity)
              next if checked.key?(var_type)
              checked[var_type] = true
              validate_usage(usage.argument_owner, usage.arg_node, var_defn_ast, usage.list_depth, path: usage.path, var_type: var_type)
            end
          end
        end
      end

      def on_argument(node, parent)
        variables = variables_in_value(node.value, 0, nil)

        if variables
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
              variables.each do |(variable, list_depth)|
                usages << FragmentVariableUsage.new(argument_owner, node, variable.name, list_depth, path)
                # Previous versions checked a fragment against the last operation before it
                if @allow_legacy_invalid_variable_usages != false && (var_defn_ast = @declared_variables[variable.name])
                  add_legacy_error(argument_owner, node, var_defn_ast, list_depth)
                end
              end
            end
          elsif argument_owner
            variables.each do |(variable, list_depth)|
              var_defn_ast = @declared_variables[variable.name]
              # Might be undefined :(
              # VariablesAreUsedAndDefined can't finalize its search until the end of the document.
              next if var_defn_ast.nil?

              legacy_reported = false
              if @allow_legacy_invalid_variable_usages != false
                # The legacy check is the same, except for a `= null` default or a variable in a nested or mixed list
                if var_defn_ast.default_value.is_a?(GraphQL::Language::Nodes::NullValue) ||
                    list_depth > 1 ||
                    (list_depth == 1 && depth_of_array(node.value) != 1)
                  add_legacy_error(argument_owner, node, var_defn_ast, list_depth)
                else
                  legacy_reported = true
                end
              end
              validate_usage(argument_owner, node, var_defn_ast, list_depth, legacy_reported: legacy_reported)
            end
          end
        end
        super
      end

      private

      # Variables inside input objects are found when their own arguments are visited.
      #: (untyped value, Integer list_depth, Array[[GraphQL::Language::Nodes::VariableIdentifier, Integer]]? variables) -> Array[[GraphQL::Language::Nodes::VariableIdentifier, Integer]]?
      def variables_in_value(value, list_depth, variables)
        case value
        when GraphQL::Language::Nodes::VariableIdentifier
          (variables ||= []) << [value, list_depth]
        when Array
          value.each { |item| variables = variables_in_value(item, list_depth + 1, variables) }
        end
        variables
      end

      #: (GraphQL::Language::Nodes::VariableDefinition ast_var, ?legacy: bool) -> untyped
      def usage_variable_type(ast_var, legacy: false)
        var_type = context.schema.type_from_ast(ast_var.type, context: context)
        return nil if var_type.nil?
        default_value = ast_var.default_value
        # An explicit `= null` default doesn't make the variable non-null (but previous versions treated it as non-null)
        if !default_value.nil? && (legacy || !default_value.is_a?(GraphQL::Language::Nodes::NullValue))
          unless var_type.kind.non_null?
            # If the value is required, but the argument is not,
            # and yet there's a non-null default, then we impliclty
            # make the argument also a required type.
            var_type = var_type.to_non_null_type
          end
        end
        var_type
      end

      # `legacy_reported:` is true when the legacy check has the same result, so an error isn't a legacy invalid usage.
      #: (untyped argument_owner, GraphQL::Language::Nodes::Argument arg_node, GraphQL::Language::Nodes::VariableDefinition ast_var, Integer list_depth, ?path: Array[String]?, ?var_type: untyped, ?legacy_reported: bool) -> void
      def validate_usage(argument_owner, arg_node, ast_var, list_depth, path: nil, var_type: usage_variable_type(ast_var), legacy_reported: false)
        return if var_type.nil?

        arg_defn = @types.argument(argument_owner, arg_node.name)
        error_message = usage_error(arg_defn, var_type, list_depth)
        return if error_message.nil?

        message_override = nil
        if @allow_legacy_invalid_variable_usages != false && !legacy_reported
          # The legacy check already added its error for this argument and variable
          return if @legacy_errors&.dig(arg_node, ast_var.name)

          if @allow_legacy_invalid_variable_usages == true
            legacy_handling = @schema.legacy_invalid_variable_usages(context.query, ast_var, arg_node)
            case legacy_handling
            when nil
              return
            when :return_validation_error
              # Add the error below
            when String
              message_override = legacy_handling
            else
              raise GraphQL::Error, "#{@schema}.legacy_invalid_variable_usages returned unexpected value: #{legacy_handling.inspect}. Expected `nil`, String, or `:return_validation_error`."
            end
          else
            context.query.logger.warn <<~WARN
              GraphQL-Ruby encountered an invalid variable usage in this query: `$#{ast_var.name}` (at #{ast_var.line}:#{ast_var.col}) for argument `#{arg_node.name}` (at #{arg_node.line}:#{arg_node.col}).
              This will return an error in future GraphQL-Ruby versions, as per the GraphQL specification
              Learn about migrating here: https://graphql-ruby.org/api-doc/#{GraphQL::VERSION}/GraphQL/Schema.html#allow_legacy_invalid_variable_usages-class_method
            WARN
            return
          end
        end

        create_error(error_message, wrap_var_type_in_lists(var_type, list_depth), ast_var, arg_defn, arg_node, path, message_override)
      end

      #: (untyped arg_defn, untyped var_type, Integer list_depth) -> String?
      def usage_error(arg_defn, var_type, list_depth)
        arg_defn_type = arg_defn.type

        # If the argument is non-null, but it was given a default value,
        # then treat it as nullable in practice, see https://github.com/rmosolgo/graphql-ruby/issues/3793
        if arg_defn_type.non_null? && arg_defn.default_value?
          arg_defn_type = arg_defn_type.of_type
        end

        var_inner_type = var_type.unwrap
        arg_inner_type = arg_defn_type.unwrap

        var_type = wrap_var_type_in_lists(var_type, list_depth)

        if var_inner_type != arg_inner_type
          "Type mismatch"
        elsif list_dimension(var_type) != list_dimension(arg_defn_type)
          "List dimension mismatch"
        elsif !non_null_levels_match(arg_defn_type, var_type)
          "Nullability mismatch"
        end
      end

      # Add the error which previous versions added for this usage, if any, so that the legacy behavior rejects the same documents.
      # They didn't check variables in nested lists, used the depth of the whole list value for each variable in it,
      # and treated a `= null` default as non-null.
      #: (untyped argument_owner, GraphQL::Language::Nodes::Argument arg_node, GraphQL::Language::Nodes::VariableDefinition ast_var, Integer list_depth) -> void
      def add_legacy_error(argument_owner, arg_node, ast_var, list_depth)
        return if list_depth > 1
        var_type = usage_variable_type(ast_var, legacy: true)
        return if var_type.nil?

        list_depth = depth_of_array(arg_node.value) if list_depth == 1
        arg_defn = @types.argument(argument_owner, arg_node.name)
        error_message = usage_error(arg_defn, var_type, list_depth)
        return if error_message.nil?

        ((@legacy_errors ||= {}.compare_by_identity)[arg_node] ||= {})[ast_var.name] = true
        create_error(error_message, wrap_var_type_in_lists(var_type, list_depth), ast_var, arg_defn, arg_node, nil, nil)
      end

      # The maximum depth of list literals in `value`
      #: (untyped value) -> Integer
      def depth_of_array(value)
        if value.is_a?(Array)
          max_child_depth = 0
          value.each do |item|
            item_depth = depth_of_array(item)
            max_child_depth = item_depth if item_depth > max_child_depth
          end
          1 + max_child_depth
        else
          0
        end
      end

      #: (String error_message, untyped var_type, GraphQL::Language::Nodes::VariableDefinition ast_var, untyped arg_defn, GraphQL::Language::Nodes::Argument arg_node, Array[String]? path, String? message_override) -> void
      def create_error(error_message, var_type, ast_var, arg_defn, arg_node, path, message_override)
        message = "#{error_message} on variable $#{ast_var.name} and argument #{arg_node.name} (#{var_type.to_type_signature} / #{arg_defn.type.to_type_signature})"
        if path
          # Many operations can use one fragment, so add each error only once.
          reported = (@reported_fragment_variable_errors ||= {}.compare_by_identity)[arg_node] ||= {}
          return if reported.key?(message)
          reported[message] = true
        end

        add_error(GraphQL::StaticValidation::VariableUsagesAreAllowedError.new(
          message_override || message,
          nodes: arg_node,
          name: ast_var.name,
          type: var_type.to_type_signature,
          argument: arg_node.name,
          error: error_message
        ), path: path)
      end

      # A variable in list literals is used as a list item, so wrap its type in one list for each list literal.
      #: (untyped var_type, Integer list_depth) -> untyped
      def wrap_var_type_in_lists(var_type, list_depth)
        list_depth.times do
          # Since the array _is_ present, treat it like a non-null type
          # (It satisfies a non-null requirement AND a nullable requirement)
          var_type = var_type.to_list_type.to_non_null_type
        end
        var_type
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
