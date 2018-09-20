# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      # The center of execution state.
      # It's mutable as a performance consideration.
      #
      # @see dup It can be "branched" to create a divergent, parallel execution state.
      #
      # TODO: merge this with `Visitor`? Why distribute this state?
      class Trace
        extend Forwardable
        def_delegators :query, :schema, :context
        attr_reader :query, :path, :objects, :types, :visitor, :lazies, :parent_trace
        attr_reader :result, :response_nodes
        def initialize(query:)
          # shared by the parent and all children:
          @query = query
          @debug = query.context[:debug_interpreter]
          @result = Interpreter::ResponseNode.new(trace: self, parent: nil)
          @response_nodes = [@result]
          @parent_trace = nil
          @lazies = []
          @types_at_paths = Hash.new { |h, k| h[k] = {} }
          # Dup'd when the parent forks:
          @path = []
          @objects = []
          @types = []
          @visitor = Visitor.new(@query.document, trace: self)
        end

        def final_value
          if @result.omitted?
            nil
          else
            @result.to_result
          end
        end

        # Copy bits of state that should be independent:
        # - @path, @objects, @types, @visitor, @result_nodes
        # Leave in place those that can be shared:
        # - @query, @result, @lazies
        def initialize_copy(original_trace)
          super
          @parent_trace = original_trace
          @path = @path.dup
          @objects = @objects.dup
          @response_nodes = @response_nodes.dup
          @types = @types.dup
          @visitor = Visitor.new(@query.document, trace: self)
        end

        def within(part, ast_node, static_type)
          next_response_node = @response_nodes.last.get_part(part)
          if next_response_node.nil?
            return
          end

          next_response_node.static_type ||= static_type
          next_response_node.dynamic_type ||= static_type
          next_response_node.ast_node ||= ast_node
          @path << part
          @types << static_type
          @response_nodes << next_response_node
          r = yield(next_response_node)
          @path.pop
          @types.pop
          @response_nodes.pop
          r
        end

        def inspect
          <<-TRACE
Path: #{@path.join(", ")}
Objects: #{@objects.map(&:inspect).join(",")}
Types: #{@types.map(&:inspect).join(",")}
Result: #{@result.inspect}
TRACE
        end

        def after_lazy(obj)
          if schema.lazy?(obj)
            # Dup it now so that `path` etc are correct
            next_trace = self.dup
            next_trace.debug "Forked at #{next_trace.path} from #{trace_id} (#{obj.inspect})"
            @lazies << GraphQL::Execution::Lazy.new do
              next_trace.debug "Resumed at #{next_trace.path} #{obj.inspect}"
              method_name = schema.lazy_method_name(obj)
              begin
                inner_obj = obj.public_send(method_name)
                next_trace.after_lazy(inner_obj) do |really_next_trace, really_inner_obj|

                  yield(really_next_trace, really_inner_obj)
                end
              rescue GraphQL::ExecutionError, GraphQL::UnauthorizedError => err
                yield(next_trace, err)
              end
            end
          else
            yield(self, obj)
          end
        end

        def arguments(arg_owner, ast_node)
          kwarg_arguments = {}
          ast_node.arguments.each do |arg|
            arg_defn = arg_owner.arguments[arg.name]
            # TODO not this
            catch(:skip) do
              value = arg_to_value(arg_defn.type, arg.value)
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

        def arg_to_value(arg_defn, ast_value)
          if ast_value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
            # If it's not here, it will get added later
            if query.variables.key?(ast_value.name)
              query.variables[ast_value.name]
            else
              throw :skip
            end
          elsif arg_defn.is_a?(GraphQL::Schema::NonNull)
            arg_to_value(arg_defn.of_type, ast_value)
          elsif arg_defn.is_a?(GraphQL::Schema::List)
            # Treat a single value like a list
            arg_value = Array(ast_value)
            arg_value.map do |inner_v|
              arg_to_value(arg_defn.of_type, inner_v)
            end
          elsif arg_defn.is_a?(Class) && arg_defn < GraphQL::Schema::InputObject
            args = arguments(arg_defn, ast_value)
            # TODO still track defaults_used?
            arg_defn.new(ruby_kwargs: args, context: context, defaults_used: nil)
          else
            flat_value = flatten_ast_value(ast_value)
            arg_defn.coerce_input(flat_value, context)
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

        def trace_id
          if @parent_trace
            "#{@parent_trace.trace_id}/#{object_id - @parent_trace.object_id}"
          else
            "0"
          end
        end

        def debug(str)
          @debug && (puts "[T#{trace_id}] #{str}")
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

        def set_type_at_path(type)
          if type.is_a?(GraphQL::Schema::LateBoundType)
            # TODO need a general way for handling these in the interpreter,
            # since they aren't removed during the cache-building stage.
            type = schema.types[type.name]
          end

          types = @types_at_paths
          @path.each do |part|
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
      end
    end
  end
end
