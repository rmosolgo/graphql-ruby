# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      # I think it would be even better if we could somehow make
      # `continue_field` not recursive. "Trampolining" it somehow.
      #
      # @api private
      class Runtime

        module GraphQLResult
          def initialize(result_name, parent_result)
            @graphql_parent = parent_result
            if parent_result && parent_result.graphql_dead
              @graphql_dead = true
            end
            @graphql_result_name = result_name
            # Jump through some hoops to avoid creating this duplicate storage if at all possible.
            @graphql_metadata = nil
          end

          attr_accessor :graphql_dead
          attr_reader :graphql_parent, :graphql_result_name

          # Although these are used by only one of the Result classes,
          # it's handy to have the methods implemented on both (even though they just return `nil`)
          # because it makes it easy to check if anything is assigned.
          # @return [nil, Array<String>]
          attr_accessor :graphql_non_null_field_names
          # @return [nil, true]
          attr_accessor :graphql_non_null_list_items

          # @return [Hash] Plain-Ruby result data (`@graphql_metadata` contains Result wrapper objects)
          attr_accessor :graphql_result_data
        end

        class GraphQLResultHash
          def initialize(_result_name, _parent_result)
            super
            @graphql_result_data = {}
          end

          include GraphQLResult

          attr_accessor :graphql_merged_into

          def []=(key, value)
            # This is a hack.
            # Basically, this object is merged into the root-level result at some point.
            # But the problem is, some lazies are created whose closures retain reference to _this_
            # object. When those lazies are resolved, they cause an update to this object.
            #
            # In order to return a proper top-level result, we have to update that top-level result object.
            # In order to return a proper partial result (eg, for a directive), we have to update this object, too.
            # Yowza.
            if (t = @graphql_merged_into)
              t[key] = value
            end

            if value.respond_to?(:graphql_result_data)
              @graphql_result_data[key] = value.graphql_result_data
              # If we encounter some part of this response that requires metadata tracking,
              # then create the metadata hash if necessary. It will be kept up-to-date after this.
              (@graphql_metadata ||= @graphql_result_data.dup)[key] = value
            else
              @graphql_result_data[key] = value
              # keep this up-to-date if it's been initialized
              @graphql_metadata && @graphql_metadata[key] = value
            end

            value
          end

          def delete(key)
            @graphql_metadata && @graphql_metadata.delete(key)
            @graphql_result_data.delete(key)
          end

          def each
            (@graphql_metadata || @graphql_result_data).each { |k, v| yield(k, v) }
          end

          def values
            (@graphql_metadata || @graphql_result_data).values
          end

          def key?(k)
            @graphql_result_data.key?(k)
          end

          def [](k)
            (@graphql_metadata || @graphql_result_data)[k]
          end
        end

        class GraphQLResultArray
          include GraphQLResult

          def initialize(_result_name, _parent_result)
            super
            @graphql_result_data = []
          end

          def graphql_skip_at(index)
            # Mark this index as dead. It's tricky because some indices may already be storing
            # `Lazy`s. So the runtime is still holding indexes _before_ skipping,
            # this object has to coordinate incoming writes to account for any already-skipped indices.
            @skip_indices ||= []
            @skip_indices << index
            offset_by = @skip_indices.count { |skipped_idx| skipped_idx < index}
            delete_at_index = index - offset_by
            @graphql_metadata && @graphql_metadata.delete_at(delete_at_index)
            @graphql_result_data.delete_at(delete_at_index)
          end

          def []=(idx, value)
            if @skip_indices
              offset_by = @skip_indices.count { |skipped_idx| skipped_idx < idx }
              idx -= offset_by
            end
            if value.respond_to?(:graphql_result_data)
              @graphql_result_data[idx] = value.graphql_result_data
              (@graphql_metadata ||= @graphql_result_data.dup)[idx] = value
            else
              @graphql_result_data[idx] = value
              @graphql_metadata && @graphql_metadata[idx] = value
            end

            value
          end

          def values
            (@graphql_metadata || @graphql_result_data)
          end
        end

        class GraphQLSelectionSet < Hash
          attr_accessor :graphql_directives
        end

        # @return [GraphQL::Query]
        attr_reader :query

        # @return [Class<GraphQL::Schema>]
        attr_reader :schema

        # @return [GraphQL::Query::Context]
        attr_reader :context

        def initialize(query:)
          @query = query
          @dataloader = query.multiplex.dataloader
          @schema = query.schema
          @context = query.context
          @multiplex_context = query.multiplex.context
          @interpreter_context = @context.namespace(:interpreter)
          @response = GraphQLResultHash.new(nil, nil)
          # Identify runtime directives by checking which of this schema's directives have overridden `def self.resolve`
          @runtime_directive_names = []
          noop_resolve_owner = GraphQL::Schema::Directive.singleton_class
          @schema_directives = schema.directives
          @schema_directives.each do |name, dir_defn|
            if dir_defn.method(:resolve).owner != noop_resolve_owner
              @runtime_directive_names << name
            end
          end
          # A cache of { Class => { String => Schema::Field } }
          # Which assumes that MyObject.get_field("myField") will return the same field
          # during the lifetime of a query
          @fields_cache = Hash.new { |h, k| h[k] = {} }
          # { Class => Boolean }
          @lazy_cache = {}
        end

        def final_result
          @response && @response.graphql_result_data
        end

        def inspect
          "#<#{self.class.name} response=#{@response.inspect}>"
        end

        def tap_or_each(obj_or_array)
          if obj_or_array.is_a?(Array)
            obj_or_array.each do |item|
              yield(item, true)
            end
          else
            yield(obj_or_array, false)
          end
        end

        # This _begins_ the execution. Some deferred work
        # might be stored up in lazies.
        # @return [void]
        def run_eager
          root_operation = query.selected_operation
          root_op_type = root_operation.operation_type || "query"
          root_type = schema.root_type_for_operation(root_op_type)
          path = []
          set_all_interpreter_context(query.root_value, nil, nil, path)
          object_proxy = authorized_new(root_type, query.root_value, context)
          object_proxy = schema.sync_lazy(object_proxy)

          if object_proxy.nil?
            # Root .authorized? returned false.
            @response = nil
          else
            call_method_on_directives(:resolve, object_proxy, root_operation.directives) do # execute query level directives
              gathered_selections = gather_selections(object_proxy, root_type, root_operation.selections)
              # This is kind of a hack -- `gathered_selections` is an Array if any of the selections
              # require isolation during execution (because of runtime directives). In that case,
              # make a new, isolated result hash for writing the result into. (That isolated response
              # is eventually merged back into the main response)
              #
              # Otherwise, `gathered_selections` is a hash of selections which can be
              # directly evaluated and the results can be written right into the main response hash.
              tap_or_each(gathered_selections) do |selections, is_selection_array|
                if is_selection_array
                  selection_response = GraphQLResultHash.new(nil, nil)
                  final_response = @response
                else
                  selection_response = @response
                  final_response = nil
                end

                @dataloader.append_job {
                  set_all_interpreter_context(query.root_value, nil, nil, path)
                  call_method_on_directives(:resolve, object_proxy, selections.graphql_directives) do
                    evaluate_selections(
                      path,
                      object_proxy,
                      root_type,
                      root_op_type == "mutation",
                      selections,
                      selection_response,
                      final_response,
                      nil,
                    )
                  end
                }
              end
            end
          end
          delete_interpreter_context(:current_path)
          delete_interpreter_context(:current_field)
          delete_interpreter_context(:current_object)
          delete_interpreter_context(:current_arguments)
          nil
        end

        # @return [void]
        def deep_merge_selection_result(from_result, into_result)
          from_result.each do |key, value|
            if !into_result.key?(key)
              into_result[key] = value
            else
              case value
              when GraphQLResultHash
                deep_merge_selection_result(value, into_result[key])
              else
                # We have to assume that, since this passed the `fields_will_merge` selection,
                # that the old and new values are the same.
                # There's no special handling of arrays because currently, there's no way to split the execution
                # of a list over several concurrent flows.
                into_result[key] = value
              end
            end
          end
          from_result.graphql_merged_into = into_result
          nil
        end

        def gather_selections(owner_object, owner_type, selections, selections_to_run = nil, selections_by_name = GraphQLSelectionSet.new)
          selections.each do |node|
            # Skip gathering this if the directive says so
            if !directives_include?(node, owner_object, owner_type)
              next
            end

            if node.is_a?(GraphQL::Language::Nodes::Field)
              response_key = node.alias || node.name
              selections = selections_by_name[response_key]
              # if there was already a selection of this field,
              # use an array to hold all selections,
              # otherise, use the single node to represent the selection
              if selections
                # This field was already selected at least once,
                # add this node to the list of selections
                s = Array(selections)
                s << node
                selections_by_name[response_key] = s
              else
                # No selection was found for this field yet
                selections_by_name[response_key] = node
              end
            else
              # This is an InlineFragment or a FragmentSpread
              if @runtime_directive_names.any? && node.directives.any? { |d| @runtime_directive_names.include?(d.name) }
                next_selections = GraphQLSelectionSet.new
                next_selections.graphql_directives = node.directives
                if selections_to_run
                  selections_to_run << next_selections
                else
                  selections_to_run = []
                  selections_to_run << selections_by_name
                  selections_to_run << next_selections
                end
              else
                next_selections = selections_by_name
              end

              case node
              when GraphQL::Language::Nodes::InlineFragment
                if node.type
                  type_defn = schema.get_type(node.type.name, context)

                  # Faster than .map{}.include?()
                  query.warden.possible_types(type_defn).each do |t|
                    if t == owner_type
                      gather_selections(owner_object, owner_type, node.selections, selections_to_run, next_selections)
                      break
                    end
                  end
                else
                  # it's an untyped fragment, definitely continue
                  gather_selections(owner_object, owner_type, node.selections, selections_to_run, next_selections)
                end
              when GraphQL::Language::Nodes::FragmentSpread
                fragment_def = query.fragments[node.name]
                type_defn = query.get_type(fragment_def.type.name)
                possible_types = query.warden.possible_types(type_defn)
                possible_types.each do |t|
                  if t == owner_type
                    gather_selections(owner_object, owner_type, fragment_def.selections, selections_to_run, next_selections)
                    break
                  end
                end
              else
                raise "Invariant: unexpected selection class: #{node.class}"
              end
            end
          end
          selections_to_run || selections_by_name
        end

        NO_ARGS = {}.freeze

        # @return [void]
        def evaluate_selections(path, owner_object, owner_type, is_eager_selection, gathered_selections, selections_result, target_result, parent_object) # rubocop:disable Metrics/ParameterLists
          set_all_interpreter_context(owner_object, nil, nil, path)

          finished_jobs = 0
          enqueued_jobs = gathered_selections.size
          gathered_selections.each do |result_name, field_ast_nodes_or_ast_node|
            @dataloader.append_job {
              evaluate_selection(
                path, result_name, field_ast_nodes_or_ast_node, owner_object, owner_type, is_eager_selection, selections_result, parent_object
              )
              finished_jobs += 1
              if target_result && finished_jobs == enqueued_jobs
                deep_merge_selection_result(selections_result, target_result)
              end
            }
          end

          selections_result
        end

        attr_reader :progress_path

        # @return [void]
        def evaluate_selection(path, result_name, field_ast_nodes_or_ast_node, owner_object, owner_type, is_eager_field, selections_result, parent_object) # rubocop:disable Metrics/ParameterLists
          return if dead_result?(selections_result)
          # As a performance optimization, the hash key will be a `Node` if
          # there's only one selection of the field. But if there are multiple
          # selections of the field, it will be an Array of nodes
          if field_ast_nodes_or_ast_node.is_a?(Array)
            field_ast_nodes = field_ast_nodes_or_ast_node
            ast_node = field_ast_nodes.first
          else
            field_ast_nodes = nil
            ast_node = field_ast_nodes_or_ast_node
          end
          field_name = ast_node.name
          # This can't use `query.get_field` because it gets confused on introspection below if `field_defn` isn't `nil`,
          # because of how `is_introspection` is used to call `.authorized_new` later on.
          field_defn = @fields_cache[owner_type][field_name] ||= owner_type.get_field(field_name, @context)
          is_introspection = false
          if field_defn.nil?
            field_defn = if owner_type == schema.query && (entry_point_field = schema.introspection_system.entry_point(name: field_name))
              is_introspection = true
              entry_point_field
            elsif (dynamic_field = schema.introspection_system.dynamic_field(name: field_name))
              is_introspection = true
              dynamic_field
            else
              raise "Invariant: no field for #{owner_type}.#{field_name}"
            end
          end
          return_type = field_defn.type

          next_path = path.dup
          next_path << result_name
          next_path.freeze

          # This seems janky, but we need to know
          # the field's return type at this path in order
          # to propagate `null`
          if return_type.non_null?
            (selections_result.graphql_non_null_field_names ||= []).push(result_name)
          end
          # Set this before calling `run_with_directives`, so that the directive can have the latest path
          set_all_interpreter_context(nil, field_defn, nil, next_path)
          object = owner_object

          if is_introspection
            object = authorized_new(field_defn.owner, object, context)
          end

          total_args_count = field_defn.arguments(context).size
          if total_args_count == 0
            resolved_arguments = GraphQL::Execution::Interpreter::Arguments::EMPTY
            evaluate_selection_with_args(resolved_arguments, field_defn, next_path, ast_node, field_ast_nodes, owner_type, object, is_eager_field, result_name, selections_result, parent_object)
          else
            # TODO remove all arguments(...) usages?
            @query.arguments_cache.dataload_for(ast_node, field_defn, object) do |resolved_arguments|
              evaluate_selection_with_args(resolved_arguments, field_defn, next_path, ast_node, field_ast_nodes, owner_type, object, is_eager_field, result_name, selections_result, parent_object)
            end
          end
        end

        def evaluate_selection_with_args(arguments, field_defn, next_path, ast_node, field_ast_nodes, owner_type, object, is_eager_field, result_name, selection_result, parent_object)  # rubocop:disable Metrics/ParameterLists
          return_type = field_defn.type
          after_lazy(arguments, owner: owner_type, field: field_defn, path: next_path, ast_node: ast_node, owner_object: object, arguments: arguments, result_name: result_name, result: selection_result) do |resolved_arguments|
            if resolved_arguments.is_a?(GraphQL::ExecutionError) || resolved_arguments.is_a?(GraphQL::UnauthorizedError)
              continue_value(next_path, resolved_arguments, owner_type, field_defn, return_type.non_null?, ast_node, result_name, selection_result)
              next
            end

            kwarg_arguments = if resolved_arguments.empty? && field_defn.extras.empty?
              # We can avoid allocating the `{ Symbol => Object }` hash in this case
              NO_ARGS
            else
              # Bundle up the extras, then make a new arguments instance
              # that includes the extras, too.
              extra_args = {}
              field_defn.extras.each do |extra|
                case extra
                when :ast_node
                  extra_args[:ast_node] = ast_node
                when :execution_errors
                  extra_args[:execution_errors] = ExecutionErrors.new(context, ast_node, next_path)
                when :path
                  extra_args[:path] = next_path
                when :lookahead
                  if !field_ast_nodes
                    field_ast_nodes = [ast_node]
                  end

                  extra_args[:lookahead] = Execution::Lookahead.new(
                    query: query,
                    ast_nodes: field_ast_nodes,
                    field: field_defn,
                  )
                when :argument_details
                  # Use this flag to tell Interpreter::Arguments to add itself
                  # to the keyword args hash _before_ freezing everything.
                  extra_args[:argument_details] = :__arguments_add_self
                when :parent
                  extra_args[:parent] = parent_object
                else
                  extra_args[extra] = field_defn.fetch_extra(extra, context)
                end
              end
              if extra_args.any?
                resolved_arguments = resolved_arguments.merge_extras(extra_args)
              end
              resolved_arguments.keyword_arguments
            end

            set_all_interpreter_context(nil, nil, resolved_arguments, nil)

            # Optimize for the case that field is selected only once
            if field_ast_nodes.nil? || field_ast_nodes.size == 1
              next_selections = ast_node.selections
              directives = ast_node.directives
            else
              next_selections = []
              directives = []
              field_ast_nodes.each { |f|
                next_selections.concat(f.selections)
                directives.concat(f.directives)
              }
            end

            field_result = call_method_on_directives(:resolve, object, directives) do
              # Actually call the field resolver and capture the result
              app_result = begin
                query.trace("execute_field", {owner: owner_type, field: field_defn, path: next_path, ast_node: ast_node, query: query, object: object, arguments: kwarg_arguments}) do
                  field_defn.resolve(object, kwarg_arguments, context)
                end
              rescue GraphQL::ExecutionError => err
                err
              rescue StandardError => err
                begin
                  query.handle_or_reraise(err)
                rescue GraphQL::ExecutionError => ex_err
                  ex_err
                end
              end
              after_lazy(app_result, owner: owner_type, field: field_defn, path: next_path, ast_node: ast_node, owner_object: object, arguments: resolved_arguments, result_name: result_name, result: selection_result) do |inner_result|
                continue_value = continue_value(next_path, inner_result, owner_type, field_defn, return_type.non_null?, ast_node, result_name, selection_result)
                if HALT != continue_value
                  continue_field(next_path, continue_value, owner_type, field_defn, return_type, ast_node, next_selections, false, object, resolved_arguments, result_name, selection_result)
                end
              end
            end

            # If this field is a root mutation field, immediately resolve
            # all of its child fields before moving on to the next root mutation field.
            # (Subselections of this mutation will still be resolved level-by-level.)
            if is_eager_field
              Interpreter::Resolve.resolve_all([field_result], @dataloader)
            else
              # Return this from `after_lazy` because it might be another lazy that needs to be resolved
              field_result
            end
          end
        end

        def dead_result?(selection_result)
          selection_result.graphql_dead || ((parent = selection_result.graphql_parent) && parent.graphql_dead)
        end

        def set_result(selection_result, result_name, value)
          if !dead_result?(selection_result)
            if value.nil? &&
                ( # there are two conditions under which `nil` is not allowed in the response:
                  (selection_result.graphql_non_null_list_items) || # this value would be written into a list that doesn't allow nils
                  ((nn = selection_result.graphql_non_null_field_names) && nn.include?(result_name)) # this value would be written into a field that doesn't allow nils
                )
              # This is an invalid nil that should be propagated
              # One caller of this method passes a block,
              # namely when application code returns a `nil` to GraphQL and it doesn't belong there.
              # The other possibility for reaching here is when a field returns an ExecutionError, so we write
              # `nil` to the response, not knowing whether it's an invalid `nil` or not.
              # (And in that case, we don't have to call the schema's handler, since it's not a bug in the application.)
              # TODO the code is trying to tell me something.
              yield if block_given?
              parent = selection_result.graphql_parent
              name_in_parent = selection_result.graphql_result_name
              if parent.nil? # This is a top-level result hash
                @response = nil
              else
                set_result(parent, name_in_parent, nil)
                set_graphql_dead(selection_result)
              end
            else
              selection_result[result_name] = value
            end
          end
        end

        # Mark this node and any already-registered children as dead,
        # so that it accepts no more writes.
        def set_graphql_dead(selection_result)
          case selection_result
          when GraphQLResultArray
            selection_result.graphql_dead = true
            selection_result.values.each { |v| set_graphql_dead(v) }
          when GraphQLResultHash
            selection_result.graphql_dead = true
            selection_result.each { |k, v| set_graphql_dead(v) }
          else
            # It's a scalar, no way to mark it dead.
          end
        end

        HALT = Object.new
        def continue_value(path, value, parent_type, field, is_non_null, ast_node, result_name, selection_result) # rubocop:disable Metrics/ParameterLists
          case value
          when nil
            if is_non_null
              set_result(selection_result, result_name, nil) do
                # This block is called if `result_name` is not dead. (Maybe a previous invalid nil caused it be marked dead.)
                err = parent_type::InvalidNullError.new(parent_type, field, value)
                schema.type_error(err, context)
              end
            else
              set_result(selection_result, result_name, nil)
            end
            HALT
          when GraphQL::Error
            # Handle these cases inside a single `when`
            # to avoid the overhead of checking three different classes
            # every time.
            if value.is_a?(GraphQL::ExecutionError)
              if selection_result.nil? || !dead_result?(selection_result)
                value.path ||= path
                value.ast_node ||= ast_node
                context.errors << value
                if selection_result
                  set_result(selection_result, result_name, nil)
                end
              end
              HALT
            elsif value.is_a?(GraphQL::UnauthorizedError)
              # this hook might raise & crash, or it might return
              # a replacement value
              next_value = begin
                schema.unauthorized_object(value)
              rescue GraphQL::ExecutionError => err
                err
              end
              continue_value(path, next_value, parent_type, field, is_non_null, ast_node, result_name, selection_result)
            elsif GraphQL::Execution::SKIP == value
              # It's possible a lazy was already written here
              case selection_result
              when GraphQLResultHash
                selection_result.delete(result_name)
              when GraphQLResultArray
                selection_result.graphql_skip_at(result_name)
              when nil
                # this can happen with directives
              else
                raise "Invariant: unexpected result class #{selection_result.class} (#{selection_result.inspect})"
              end
              HALT
            else
              # What could this actually _be_? Anyhow,
              # preserve the default behavior of doing nothing with it.
              value
            end
          when Array
            # It's an array full of execution errors; add them all.
            if value.any? && value.all? { |v| v.is_a?(GraphQL::ExecutionError) }
              list_type_at_all = (field && (field.type.list?))
              if selection_result.nil? || !dead_result?(selection_result)
                value.each_with_index do |error, index|
                  error.ast_node ||= ast_node
                  error.path ||= path + (list_type_at_all ? [index] : [])
                  context.errors << error
                end
                if selection_result
                  if list_type_at_all
                    result_without_errors = value.map { |v| v.is_a?(GraphQL::ExecutionError) ? nil : v }
                    set_result(selection_result, result_name, result_without_errors)
                  else
                    set_result(selection_result, result_name, nil)
                  end
                end
              end
              HALT
            else
              value
            end
          when GraphQL::Execution::Interpreter::RawValue
            # Write raw value directly to the response without resolving nested objects
            set_result(selection_result, result_name, value.resolve)
            HALT
          else
            value
          end
        end

        # The resolver for `field` returned `value`. Continue to execute the query,
        # treating `value` as `type` (probably the return type of the field).
        #
        # Use `next_selections` to resolve object fields, if there are any.
        #
        # Location information from `path` and `ast_node`.
        #
        # @return [Lazy, Array, Hash, Object] Lazy, Array, and Hash are all traversed to resolve lazy values later
        def continue_field(path, value, owner_type, field, current_type, ast_node, next_selections, is_non_null, owner_object, arguments, result_name, selection_result) # rubocop:disable Metrics/ParameterLists
          if current_type.non_null?
            current_type = current_type.of_type
            is_non_null = true
          end

          case current_type.kind.name
          when "SCALAR", "ENUM"
            r = current_type.coerce_result(value, context)
            set_result(selection_result, result_name, r)
            r
          when "UNION", "INTERFACE"
            resolved_type_or_lazy, resolved_value = resolve_type(current_type, value, path)
            resolved_value ||= value

            after_lazy(resolved_type_or_lazy, owner: current_type, path: path, ast_node: ast_node, field: field, owner_object: owner_object, arguments: arguments, trace: false, result_name: result_name, result: selection_result) do |resolved_type|
              possible_types = query.possible_types(current_type)

              if !possible_types.include?(resolved_type)
                parent_type = field.owner_type
                err_class = current_type::UnresolvedTypeError
                type_error = err_class.new(resolved_value, field, parent_type, resolved_type, possible_types)
                schema.type_error(type_error, context)
                set_result(selection_result, result_name, nil)
                nil
              else
                continue_field(path, resolved_value, owner_type, field, resolved_type, ast_node, next_selections, is_non_null, owner_object, arguments, result_name, selection_result)
              end
            end
          when "OBJECT"
            object_proxy = begin
              authorized_new(current_type, value, context)
            rescue GraphQL::ExecutionError => err
              err
            end
            after_lazy(object_proxy, owner: current_type, path: path, ast_node: ast_node, field: field, owner_object: owner_object, arguments: arguments, trace: false, result_name: result_name, result: selection_result) do |inner_object|
              continue_value = continue_value(path, inner_object, owner_type, field, is_non_null, ast_node, result_name, selection_result)
              if HALT != continue_value
                response_hash = GraphQLResultHash.new(result_name, selection_result)
                set_result(selection_result, result_name, response_hash)
                gathered_selections = gather_selections(continue_value, current_type, next_selections)
                # There are two possibilities for `gathered_selections`:
                # 1. All selections of this object should be evaluated together (there are no runtime directives modifying execution).
                #    This case is handled below, and the result can be written right into the main `response_hash` above.
                #    In this case, `gathered_selections` is a hash of selections.
                # 2. Some selections of this object have runtime directives that may or may not modify execution.
                #    That part of the selection is evaluated in an isolated way, writing into a sub-response object which is
                #    eventually merged into the final response. In this case, `gathered_selections` is an array of things to run in isolation.
                #    (Technically, it's possible that one of those entries _doesn't_ require isolation.)
                tap_or_each(gathered_selections) do |selections, is_selection_array|
                  if is_selection_array
                    this_result = GraphQLResultHash.new(result_name, selection_result)
                    final_result = response_hash
                  else
                    this_result = response_hash
                    final_result = nil
                  end
                  set_all_interpreter_context(continue_value, nil, nil, path) # reset this mutable state
                  call_method_on_directives(:resolve, continue_value, selections.graphql_directives) do
                    evaluate_selections(
                      path,
                      continue_value,
                      current_type,
                      false,
                      selections,
                      this_result,
                      final_result,
                      owner_object.object,
                    )
                    this_result
                  end
                end
              end
            end
          when "LIST"
            inner_type = current_type.of_type
            # This is true for objects, unions, and interfaces
            use_dataloader_job = !inner_type.unwrap.kind.input?
            response_list = GraphQLResultArray.new(result_name, selection_result)
            response_list.graphql_non_null_list_items = inner_type.non_null?
            set_result(selection_result, result_name, response_list)

            idx = 0
            begin
              value.each do |inner_value|
                break if dead_result?(response_list)
                next_path = path.dup
                next_path << idx
                this_idx = idx
                next_path.freeze
                idx += 1
                if use_dataloader_job
                  @dataloader.append_job do
                    resolve_list_item(inner_value, inner_type, next_path, ast_node, field, owner_object, arguments, this_idx, response_list, next_selections, owner_type)
                  end
                else
                  resolve_list_item(inner_value, inner_type, next_path, ast_node, field, owner_object, arguments, this_idx, response_list, next_selections, owner_type)
                end
              end
            rescue NoMethodError => err
              # Ruby 2.2 doesn't have NoMethodError#receiver, can't check that one in this case. (It's been EOL since 2017.)
              if err.name == :each && (err.respond_to?(:receiver) ? err.receiver == value : true)
                # This happens when the GraphQL schema doesn't match the implementation. Help the dev debug.
                raise ListResultFailedError.new(value: value, field: field, path: path)
              else
                # This was some other NoMethodError -- let it bubble to reveal the real error.
                raise
              end
            end

            response_list
          else
            raise "Invariant: Unhandled type kind #{current_type.kind} (#{current_type})"
          end
        end

        def resolve_list_item(inner_value, inner_type, next_path, ast_node, field, owner_object, arguments, this_idx, response_list, next_selections, owner_type) # rubocop:disable Metrics/ParameterLists
          set_all_interpreter_context(nil, nil, nil, next_path)
          call_method_on_directives(:resolve_each, owner_object, ast_node.directives) do
            # This will update `response_list` with the lazy
            after_lazy(inner_value, owner: inner_type, path: next_path, ast_node: ast_node, field: field, owner_object: owner_object, arguments: arguments, result_name: this_idx, result: response_list) do |inner_inner_value|
              continue_value = continue_value(next_path, inner_inner_value, owner_type, field, inner_type.non_null?, ast_node, this_idx, response_list)
              if HALT != continue_value
                continue_field(next_path, continue_value, owner_type, field, inner_type, ast_node, next_selections, false, owner_object, arguments, this_idx, response_list)
              end
            end
          end
        end

        def call_method_on_directives(method_name, object, directives, &block)
          return yield if directives.nil? || directives.empty?
          run_directive(method_name, object, directives, 0, &block)
        end

        def run_directive(method_name, object, directives, idx, &block)
          dir_node = directives[idx]
          if !dir_node
            yield
          else
            dir_defn = @schema_directives.fetch(dir_node.name)
            raw_dir_args = arguments(nil, dir_defn, dir_node)
            dir_args = continue_value(
              @context[:current_path], # path
              raw_dir_args, # value
              dir_defn, # parent_type
              nil, # field
              false, # is_non_null
              dir_node, # ast_node
              nil, # result_name
              nil, # selection_result
            )

            if dir_args == HALT
              nil
            else
              dir_defn.public_send(method_name, object, dir_args, context) do
                run_directive(method_name, object, directives, idx + 1, &block)
              end
            end
          end
        end

        # Check {Schema::Directive.include?} for each directive that's present
        def directives_include?(node, graphql_object, parent_type)
          node.directives.each do |dir_node|
            dir_defn = @schema_directives.fetch(dir_node.name)
            args = arguments(graphql_object, dir_defn, dir_node)
            if !dir_defn.include?(graphql_object, args, context)
              return false
            end
          end
          true
        end

        def set_all_interpreter_context(object, field, arguments, path)
          if object
            @context[:current_object] = @interpreter_context[:current_object] = object
          end
          if field
            @context[:current_field] = @interpreter_context[:current_field] = field
          end
          if arguments
            @context[:current_arguments] = @interpreter_context[:current_arguments] = arguments
          end
          if path
            @context[:current_path] = @interpreter_context[:current_path] = path
          end
        end

        # @param obj [Object] Some user-returned value that may want to be batched
        # @param path [Array<String>]
        # @param field [GraphQL::Schema::Field]
        # @param eager [Boolean] Set to `true` for mutation root fields only
        # @param trace [Boolean] If `false`, don't wrap this with field tracing
        # @return [GraphQL::Execution::Lazy, Object] If loading `object` will be deferred, it's a wrapper over it.
        def after_lazy(lazy_obj, owner:, field:, path:, owner_object:, arguments:, ast_node:, result:, result_name:, eager: false, trace: true, &block)
          if lazy?(lazy_obj)
            lazy = GraphQL::Execution::Lazy.new(path: path, field: field) do
              set_all_interpreter_context(owner_object, field, arguments, path)
              # Wrap the execution of _this_ method with tracing,
              # but don't wrap the continuation below
              inner_obj = begin
                if trace
                  query.trace("execute_field_lazy", {owner: owner, field: field, path: path, query: query, object: owner_object, arguments: arguments, ast_node: ast_node}) do
                    schema.sync_lazy(lazy_obj)
                  end
                else
                  schema.sync_lazy(lazy_obj)
                end
              rescue GraphQL::ExecutionError, GraphQL::UnauthorizedError => ex_err
                ex_err
              rescue StandardError => err
                begin
                  query.handle_or_reraise(err)
                rescue GraphQL::ExecutionError => ex_err
                  ex_err
                end
              end
              yield(inner_obj)
            end

            if eager
              lazy.value
            else
              set_result(result, result_name, lazy)
              lazy
            end
          else
            set_all_interpreter_context(owner_object, field, arguments, path)
            yield(lazy_obj)
          end
        end

        def arguments(graphql_object, arg_owner, ast_node)
          if arg_owner.arguments_statically_coercible?
            query.arguments_for(ast_node, arg_owner)
          else
            # The arguments must be prepared in the context of the given object
            query.arguments_for(ast_node, arg_owner, parent_object: graphql_object)
          end
        end

        # Set this pair in the Query context, but also in the interpeter namespace,
        # for compatibility.
        def set_interpreter_context(key, value)
          @interpreter_context[key] = value
          @context[key] = value
        end

        def delete_interpreter_context(key)
          @interpreter_context.delete(key)
          @context.delete(key)
        end

        def resolve_type(type, value, path)
          trace_payload = { context: context, type: type, object: value, path: path }
          resolved_type, resolved_value = query.trace("resolve_type", trace_payload) do
            query.resolve_type(type, value)
          end

          if lazy?(resolved_type)
            GraphQL::Execution::Lazy.new do
              query.trace("resolve_type_lazy", trace_payload) do
                schema.sync_lazy(resolved_type)
              end
            end
          else
            [resolved_type, resolved_value]
          end
        end

        def authorized_new(type, value, context)
          type.authorized_new(value, context)
        end

        def lazy?(object)
          @lazy_cache.fetch(object.class) {
            @lazy_cache[object.class] = @schema.lazy?(object)
          }
        end
      end
    end
  end
end
