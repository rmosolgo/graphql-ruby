# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      # The center of execution state.
      # It's mutable as a performance consideration.
      # (TODO provide explicit APIs for providing stuff to user code)
      # It can be "branched" to create a divergent, parallel execution state.
      # (TODO create branching API and prove its value)
      #
      # TODO: merge this with `Visitor`? Why distribute this state?
      class Trace
        extend Forwardable
        def_delegators :query, :schema, :context
        attr_reader :query, :path, :objects, :result, :types, :visitor, :lazies, :parent_trace

        def initialize(query:)
          @query = query
          @path = []
          @result = {}
          @objects = []
          @types = []
          @lazies = []
          @parent_trace = nil
          @visitor = Visitor.new(@query.document, trace: self)
        end

        # Copy bits of state that should be independent:
        # - @path, @objects, @types, @visitor
        # Leave in place those that can be shared:
        # - @query, @result, @lazies
        def initialize_copy(original_trace)
          super
          @parent_trace = original_trace
          @path = @path.dup
          @objects = @objects.dup
          @types = @types.dup
          @visitor = Visitor.new(@query.document, trace: self)
        end

        def with_path(part)
          @path << part
          r = yield
          @path.pop
          r
        end

        def with_type(type)
          @types << type
          r = yield
          @types.pop
          r
        end

        def with_object(obj)
          @objects << obj
          r = yield
          @objects.pop
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

        # TODO delegate to a collector which does as it pleases with patches
        def write(value)
          write_target = @result ||= {}
          @path.each_with_index do |path_part, idx|
            next_part = @path[idx + 1]
            debug [write_target, path_part, next_part]
            if next_part.nil?
              write_target[path_part] = value
            elsif next_part.is_a?(Integer)
              write_target = write_target[path_part] ||= []
            else
              write_target = write_target[path_part] ||= {}
            end
          end
          nil
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
            value = arg_to_value(arg_defn.type, arg.value)
            kwarg_arguments[arg_defn.keyword] = value
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
            query.variables[ast_value.name]
          elsif arg_defn.is_a?(GraphQL::Schema::NonNull)
            arg_to_value(arg_defn.of_type, ast_value)
          elsif arg_defn.is_a?(GraphQL::Schema::List)
            ast_value.map do |inner_v|
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
          # puts "[T#{trace_id}] #{str}"
        end
      end
    end
  end
end
