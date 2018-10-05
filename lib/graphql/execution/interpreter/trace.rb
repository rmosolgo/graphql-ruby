# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      # The center of execution state.
      # It's mutable as a performance consideration.
      #
      # TODO rename so it doesn't conflict with `GraphQL::Tracing`.
      class Trace
        extend Forwardable
        def_delegators :query, :schema, :context
        # TODO document these methods
        attr_reader :query, :result, :lazies, :parent_trace

        def initialize(query:, lazies:)
          # shared by the parent and all children:
          @query = query
          @debug = query.context[:debug_interpreter]
          @result = {}
          @lazies = lazies
          @completely_nulled = false
          @types_at_paths = Hash.new { |h, k| h[k] = {} }
        end

        def final_value
          if @completely_nulled
            nil
          else
            @result
          end
        end

        def inspect
          "#<#{self.class.name} result=#{@result.inspect}>"
        end

        # TODO delegate to a collector which does as it pleases with patches
        def write(path, value, propagating_nil: false)
          if @completely_nulled
            nil
          else
            res = @result ||= {}
            if path_exists?(path)
              write_into_result(res, path, value, propagating_nil: propagating_nil)
            end
          end
        end

        # TODO: isolate calls to this. Am I missing something?
        # @param field [GraphQL::Schema::Field]
        # @param eager [Boolean] Set to `true` for mutation root fields only
        def after_lazy(obj, field:, path:, eager: false)
          if schema.lazy?(obj)
            lazy = GraphQL::Execution::Lazy.new do
              # Wrap the execution of _this_ method with tracing,
              # but don't wrap the continuation below
              inner_obj = query.trace("execute_field_lazy", {field: field, path: path}) do
                method_name = schema.lazy_method_name(obj)
                begin
                  obj.public_send(method_name)
                rescue GraphQL::ExecutionError, GraphQL::UnauthorizedError => err
                  yield(err)
                end
              end
              after_lazy(inner_obj, field: field, path: path, eager: eager) do |really_inner_obj|
                yield(really_inner_obj)
              end
            end

            if eager
              lazy.value
            else
              @lazies << lazy
            end
          else
            yield(obj)
          end
        end

        def arguments(graphql_object, arg_owner, ast_node)
          kwarg_arguments = {}
          ast_node.arguments.each do |arg|
            arg_defn = arg_owner.arguments[arg.name]
            # Need to distinguish between client-provided `nil`
            # and nothing-at-all
            is_present, value = arg_to_value(graphql_object, arg_defn.type, arg.value)
            if is_present
              # This doesn't apply to directives, which are legacy
              # Can remove this when Skip and Include use classes or something.
              if graphql_object
                value = arg_defn.prepare_value(graphql_object, value)
              end
              kwarg_arguments[arg_defn.keyword] = value
            end
          end
          arg_owner.arguments.each do |name, arg_defn|
            if arg_defn.default_value? && !kwarg_arguments.key?(arg_defn.keyword)
              kwarg_arguments[arg_defn.keyword] = arg_defn.default_value
            end
          end
          kwarg_arguments
        end

        # Get a Ruby-ready value from a client query.
        # @param graphql_object [Object] The owner of the field whose argument this is
        # @param arg_type [Class, GraphQL::Schema::NonNull, GraphQL::Schema::List]
        # @param ast_value [GraphQL::Language::Nodes::VariableIdentifier, String, Integer, Float, Boolean]
        # @return [Array(is_present, value)]
        def arg_to_value(graphql_object, arg_type, ast_value)
          if ast_value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
            # If it's not here, it will get added later
            if query.variables.key?(ast_value.name)
              return true, query.variables[ast_value.name]
            else
              return false, nil
            end
          elsif arg_type.is_a?(GraphQL::Schema::NonNull)
            arg_to_value(graphql_object, arg_type.of_type, ast_value)
          elsif arg_type.is_a?(GraphQL::Schema::List)
            # Treat a single value like a list
            arg_value = Array(ast_value)
            list = []
            arg_value.map do |inner_v|
              _present, value = arg_to_value(graphql_object, arg_type.of_type, inner_v)
              list << value
            end
            return true, list
          elsif arg_type.is_a?(Class) && arg_type < GraphQL::Schema::InputObject
            # For these, `prepare` is applied during `#initialize`.
            # Pass `nil` so it will be skipped in `#arguments`.
            # What a mess.
            args = arguments(nil, arg_type, ast_value)
            # TODO still track defaults_used?
            return true, arg_type.new(ruby_kwargs: args, context: context, defaults_used: nil)
          else
            flat_value = flatten_ast_value(ast_value)
            return true, arg_type.coerce_input(flat_value, context)
          end
        end

        def flatten_ast_value(v)
          case v
          when GraphQL::Language::Nodes::Enum
            v.name
          when GraphQL::Language::Nodes::InputObject
            h = {}
            v.arguments.each do |arg|
              h[arg.name] = flatten_ast_value(arg.value)
            end
            h
          when Array
            v.map { |v2| flatten_ast_value(v2) }
          when GraphQL::Language::Nodes::VariableIdentifier
            flatten_ast_value(query.variables[v.name])
          else
            v
          end
        end

        def debug(str)
          @debug && (puts "[Trace] #{str}")
        end

        # TODO this is kind of a hack.
        # To propagate nulls, we have to know what the field type was
        # at previous parts of the response.
        # This hash matches the response
        def type_at(path)
          t = @types_at_paths
          path.each do |part|
            if part.is_a?(Integer)
              part = 0
            end
            t = t[part] || (raise("Invariant: #{part.inspect} not found in #{t}"))
          end
          t = t[:__type]
          t
        end

        def set_type_at_path(path, type)
          types = @types_at_paths
          path.each do |part|
            if part.is_a?(Integer)
              part = 0
            end

            types = types[part] ||= {}
          end
          # Use this magic key so that the hash contains:
          # - string keys for nested fields
          # - :__type for the object type of a selection
          types[:__type] ||= type
          nil
        end

        private

        # @return [Boolean] True if `@result` contains a value at `path`
        def path_exists?(path)
          res = @result
          path[0..-2].each do |part|
            if res
              res = res[part]
            else
              return false
            end
          end
          !!res
        end

        # Write `value` at `path` in `result`. If `propagating_nil` is true, `nil` may override
        # part of the already-written response.
        # @return [void]
        def write_into_result(result, path, value, propagating_nil:)
          if value.is_a?(GraphQL::ExecutionError) || (value.is_a?(Array) && value.any? && value.all? { |v| v.is_a?(GraphQL::ExecutionError)})
            Array(value).each do |v|
              context.errors << v
            end
            write_into_result(result, path, nil, propagating_nil: propagating_nil)
          elsif value.is_a?(GraphQL::InvalidNullError)
            schema.type_error(value, context)
            write_into_result(result, path, nil, propagating_nil: true)
          elsif value.nil? && type_at(path).non_null?
            # This nil is invalid, try writing it at the previous spot
            propagate_path = path[0..-2]

            if propagate_path.empty?
              @completely_nulled = true
            else
              write_into_result(result, propagate_path, value, propagating_nil: true)
            end
          else
            write_target = result
            path.each_with_index do |path_part, idx|
              next_part = path[idx + 1]
              if next_part.nil?
                if write_target[path_part].nil? || (propagating_nil)
                  write_target[path_part] = value
                else
                  raise "Invariant: Duplicate write to #{path} (previous: #{write_target[path_part].inspect}, new: #{value.inspect})"
                end
              else
                write_target = write_target.fetch(path_part, :__unset)
                if write_target.nil?
                  # TODO how can we _halt_ execution when this happens?
                  # rather than calculating the value but failing to write it,
                  # can we just not resolve those lazy things?
                  break
                end
              end
            end
          end
          nil
        end
      end
    end
  end
end
