# frozen_string_literal: true
module GraphQL
  module Execution
    class Interpreter
      # The visitor itself is stateless,
      # it delegates state to the `trace`
      class Visitor < GraphQL::Language::Visitor
        extend Forwardable
        def_delegators :@trace, :query, :schema, :context
        attr_reader :trace

        def initialize(document, trace:)
          super(document)
          @trace = trace
        end

        def on_operation_definition(node, _parent)
          if node == query.selected_operation
            root_type = schema.root_type_for_operation(node.operation_type || "query")
            root_type = root_type.metadata[:type_class]
            object_proxy = root_type.authorized_new(query.root_value, query.context)
            trace.with_type(root_type) do
              trace.with_object(object_proxy) do
                super
              end
            end
          end
        end

        def on_fragment_definition(node, parent)
          # Do nothing, not executable
        end

        def on_fragment_spread(node, _parent)
          fragment_def = query.fragments[node.name]
          type_defn = schema.types[fragment_def.type.name]
          type_defn = type_defn.metadata[:type_class]
          possible_types = schema.possible_types(type_defn).map { |t| t.metadata[:type_class] }
          if possible_types.include?(trace.types.last)
            fragment_def.selections.each do |selection|
              visit_node(selection, fragment_def)
            end
          end
        end

        def on_inline_fragment(node, _parent)
          if node.type
            type_defn = schema.types[node.type.name]
            type_defn = type_defn.metadata[:type_class]
            possible_types = schema.possible_types(type_defn).map { |t| t.metadata[:type_class] }
            if possible_types.include?(trace.types.last)
              super
            end
          else
            super
          end
        end

        def on_field(node, _parent)
          # TODO call out to directive here
          node.directives.each do |dir|
            dir_defn = schema.directives.fetch(dir.name)
            if dir.name == "skip" && trace.arguments(dir_defn, dir)[:if] == true
              return
            elsif dir.name == "include" && trace.arguments(dir_defn, dir)[:if] == false
              return
            end
          end

          field_name = node.name
          field_defn = trace.types.last.fields[field_name]
          is_introspection = false
          if field_defn.nil?
            field_defn = if trace.types.last == schema.query.metadata[:type_class] && (entry_point_field = schema.introspection_system.entry_point(name: field_name))
                           is_introspection = true
                           entry_point_field.metadata[:type_class]
                         elsif (dynamic_field = schema.introspection_system.dynamic_field(name: field_name))
                           is_introspection = true
                           dynamic_field.metadata[:type_class]
                         else
                           raise "Invariant: no field for #{trace.types.last}.#{field_name}"
                         end
          end

          trace.with_path(node.alias || node.name) do
            object = trace.objects.last
            if is_introspection
              object = field_defn.owner.authorized_new(object, context)
            end
            kwarg_arguments = trace.arguments(field_defn, node)
            # TODO: very shifty that these cached Hashes are being modified
            if field_defn.extras.include?(:ast_node)
              kwarg_arguments[:ast_node] = node
            end
            if field_defn.extras.include?(:execution_errors)
              kwarg_arguments[:execution_errors] = ExecutionErrors.new(context, node, trace.path.dup)
            end

            result = begin
                       begin
                         field_defn.resolve_field_2(object, kwarg_arguments, context)
                       rescue GraphQL::UnauthorizedError => err
                         schema.unauthorized_object(err)
                       end
                     rescue GraphQL::ExecutionError => err
                       err
                     end
            continue_field(field_defn.type, result) do
              super
            end
          end
        end

        def continue_field(type, value)
          if value.nil?
            trace.write(nil)
            return
          elsif value.is_a?(GraphQL::ExecutionError)
            # TODO this probably needs the path added somewhere
            context.errors << value
            trace.write(nil)
            return
          elsif GraphQL::Execution::Execute::SKIP == value
            return
          end

          if type.is_a?(GraphQL::Schema::LateBoundType)
            type = query.warden.get_type(type.name).metadata[:type_class]
          end

          case type.kind
          when TypeKinds::SCALAR, TypeKinds::ENUM
            r = type.coerce_result(value, query.context)
            trace.write(r)
          when TypeKinds::UNION, TypeKinds::INTERFACE
            obj_type = schema.resolve_type(type, value, query.context)
            obj_type = obj_type.metadata[:type_class]
            object_proxy = obj_type.authorized_new(value, query.context)
            trace.with_type(obj_type) do
              trace.with_object(object_proxy) do
                yield
              end
            end
          when TypeKinds::OBJECT
            object_proxy = type.authorized_new(value, query.context)
            trace.with_type(type) do
              trace.with_object(object_proxy) do
                yield
              end
            end
          when TypeKinds::LIST
            value.each_with_index.map do |inner_value, idx|
              trace.with_path(idx) do
                continue_field(type.of_type, inner_value) { yield }
              end
            end
          when TypeKinds::NON_NULL
            continue_field(type.of_type, value) { yield }
          else
            raise "Invariant: Unhandled type kind #{type.kind} (#{type})"
          end
        end
      end

      # This method is the Executor API
      # TODO revisit Executor's reason for living.
      def execute(_ast_operation, _root_type, query)
        @query = query
        @schema = query.schema
        evaluate
      end

      def evaluate
        trace = Trace.new(query: @query)
        visitor = Visitor.new(@query.document, trace: trace)
        visitor.visit
        trace.result
      rescue
        puts $!.message
        puts trace.inspect
        raise
      end

      # TODO I wish I could just _not_ support this.
      # It's counter to the spec. It's hard to maintain.
      class ExecutionErrors
        def initialize(ctx, ast_node, path)
          @context = ctx
          @ast_node = ast_node
          @path = path
        end

        def add(err_or_msg)
          err = case err_or_msg
                when String
                  GraphQL::ExecutionError.new(err_or_msg)
                when GraphQL::ExecutionError
                  err_or_msg
                else
                  raise ArgumentError, "expected String or GraphQL::ExecutionError, not #{err_or_msg.class} (#{err_or_msg.inspect})"
                end
          err.ast_node ||= @ast_node
          err.path ||= @path
          @context.add_error(err)
        end
      end

      # The center of execution state.
      # It's mutable as a performance consideration.
      # (TODO provide explicit APIs for providing stuff to user code)
      # It can be "branched" to create a divergent, parallel execution state.
      # (TODO create branching API and prove its value)
      class Trace
        extend Forwardable
        def_delegators :query, :schema, :context
        attr_reader :query, :path, :objects, :result, :types

        def initialize(query:)
          @query = query
          @path = []
          @result = nil
          @objects = []
          @types = []
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

        def write(value)
          write_target = @result ||= {}
          @path.each_with_index do |path_part, idx|
            next_part = @path[idx + 1]
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

        def arguments(arg_owner, ast_node)
          kwarg_arguments = {}
          ast_node.arguments.each do |arg|
            arg_defn = arg_owner.arguments[arg.name]
            value = arg_to_value(arg_defn.type, arg.value)

            kwarg_arguments[arg_defn.keyword] = value
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
      end
    end
  end
end
