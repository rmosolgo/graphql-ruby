# frozen_string_literal: true
module GraphQL
  class Schema
    class Member
      module HasArguments
        def self.included(cls)
          cls.extend(ArgumentClassAccessor)
          cls.include(ArgumentObjectLoader)
        end

        def self.extended(cls)
          cls.extend(ArgumentClassAccessor)
          cls.include(ArgumentObjectLoader)
          cls.extend(ClassConfigured)
        end

        # **Parameters**
        #
        # - `arg_name` (`Symbol`) — The underscore-cased name of this argument, `name:` keyword also accepted
        # - `type_expr` — The GraphQL type of this argument; `type:` keyword also accepted
        # - `desc` (`String`) — Argument description, `description:` keyword also accepted
        # - `definition_block` (`Proc`) — Called with the newly-created [Argument](rdoc-ref:Argument)
        # - `kwargs` (`Hash`) — Keywords for defining an argument. Any keywords not documented here must be handled by your base Argument class.
        #
        # **Options**
        #
        # - `kwargs.:required` (`Boolean, :nullable`) — if true, this argument is non-null; if false, this argument is nullable. If `:nullable`, then the argument must be provided, though it may be `null`.
        # - `kwargs.:description` (`String`) — Positional argument also accepted
        # - `kwargs.:type` (`Class, Array<Class>`) — Input type; positional argument also accepted
        # - `kwargs.:name` (`Symbol`) — positional argument also accepted
        # - `kwargs.:default_value` (`Object`)
        # - `kwargs.:loads` (`Class, Array<Class>`) — A GraphQL type to load for the given ID when one is present
        # - `kwargs.:as` (`Symbol`) — Override the keyword name when passed to a method
        # - `kwargs.:prepare` (`Symbol`) — A method to call to transform this argument's valuebefore sending it to field resolution
        # - `kwargs.:camelize` (`Boolean`) — if true, the name will be camelized when building the schema
        # - `kwargs.:from_resolver` (`Boolean`) — if true, a Resolver class defined this argument
        # - `kwargs.:directives` (`Hash{Class => Hash}`)
        # - `kwargs.:deprecation_reason` (`String`)
        # - `kwargs.:comment` (`String`) — Private, used by GraphQL-Ruby when parsing GraphQL schema files
        # - `kwargs.:ast_node` (`GraphQL::Language::Nodes::InputValueDefinition`) — Private, used by GraphQL-Ruby when parsing schema files
        # - `kwargs.:validates` (`Hash, nil`) — Options for building validators, if any should be applied
        # - `kwargs.:replace_null_with_default` (`Boolean`) — if `true`, incoming values of `null` will be replaced with the configured `default_value`
        #
        # **Returns**
        #
        # - `GraphQL::Schema::Argument` — An instance of [argument_class](rdoc-ref:argument_class) created from these arguments
        #
        # :call-seq:
        #   argument(Symbol arg_name, type_expr, String desc, Hash **kwargs, Proc &definition_block) -> GraphQL::Schema::Argument
        def argument(arg_name = nil, type_expr = nil, desc = nil, **kwargs, &definition_block)
          if kwargs[:loads]
            loads_name = arg_name || kwargs[:name]
            loads_name_as_string = loads_name.to_s

            inferred_arg_name = case loads_name_as_string
            when /_id$/
              loads_name_as_string.sub(/_id$/, "").to_sym
            when /_ids$/
              loads_name_as_string.sub(/_ids$/, "")
                .sub(/([^s])$/, "\\1s")
                .to_sym
            else
              loads_name
            end

            kwargs[:as] ||= inferred_arg_name
          end
          kwargs[:owner] = self
          arg_defn = self.argument_class.new(
            arg_name, type_expr, desc,
            **kwargs,
            &definition_block
          )
          add_argument(arg_defn)
          arg_defn
        end

        # Register this argument with the class.
        #
        # **Parameters**
        #
        # - `arg_defn` (`GraphQL::Schema::Argument`)
        #
        # **Returns**
        #
        # - `GraphQL::Schema::Argument`
        #
        # :call-seq:
        #   add_argument(GraphQL::Schema::Argument arg_defn) -> GraphQL::Schema::Argument
        def add_argument(arg_defn)
          @own_arguments ||= {}
          prev_defn = @own_arguments[arg_defn.name]
          case prev_defn
          when nil
            @own_arguments[arg_defn.name] = arg_defn
          when Array
            prev_defn << arg_defn
          when GraphQL::Schema::Argument
            @own_arguments[arg_defn.name] = [prev_defn, arg_defn]
          else
            raise "Invariant: unexpected `@own_arguments[#{arg_defn.name.inspect}]`: #{prev_defn.inspect}"
          end
          arg_defn
        end

        def remove_argument(arg_defn)
          prev_defn = @own_arguments[arg_defn.name]
          case prev_defn
          when nil
            # done
          when Array
            prev_defn.delete(arg_defn)
          when GraphQL::Schema::Argument
            @own_arguments.delete(arg_defn.name)
          else
            raise "Invariant: unexpected `@own_arguments[#{arg_defn.name.inspect}]`: #{prev_defn.inspect}"
          end
          nil
        end

        # **Returns**
        #
        # - `Hash<String => GraphQL::Schema::Argument>` — Arguments defined on this thing, keyed by name. Includes inherited definitions
        #
        # :call-seq:
        #   arguments(context:, _require_defined_arguments) -> Hash[String, GraphQL::Schema::Argument]
        def arguments(context = GraphQL::Query::NullContext.instance, _require_defined_arguments = nil)
          if !own_arguments.empty?
            own_arguments_that_apply = {}
            own_arguments.each do |name, args_entry|
              if (visible_defn = Warden.visible_entry?(:visible_argument?, args_entry, context))
                own_arguments_that_apply[visible_defn.graphql_name] = visible_defn
              end
            end
          end
          # might be nil if there are actually no arguments
          own_arguments_that_apply || own_arguments
        end

        def any_arguments?
          !own_arguments.empty?
        end

        module ClassConfigured
          def inherited(child_class)
            super
            child_class.extend(InheritedArguments)
          end

          module InheritedArguments
            def arguments(context = GraphQL::Query::NullContext.instance, require_defined_arguments = true)
              own_arguments = super(context, require_defined_arguments)
              inherited_arguments = superclass.arguments(context, false)

              if !own_arguments.empty?
                if !inherited_arguments.empty?
                  # Local definitions override inherited ones
                  inherited_arguments.merge(own_arguments)
                else
                  own_arguments
                end
              else
                inherited_arguments
              end
            end

            def any_arguments?
              super || superclass.any_arguments?
            end

            def all_argument_definitions
              all_defns = {}
              ancestors.reverse_each do |ancestor|
                if ancestor.respond_to?(:own_arguments)
                  all_defns.merge!(ancestor.own_arguments)
                end
              end
              all_defns = all_defns.values
              all_defns.flatten!
              all_defns
            end


            def get_argument(argument_name, context = GraphQL::Query::NullContext.instance)
              warden = Warden.from_context(context)
              skip_visible = context.respond_to?(:types) && context.types.is_a?(GraphQL::Schema::Visibility::Profile)
              for ancestor in ancestors
                if ancestor.respond_to?(:own_arguments) &&
                  (a = ancestor.own_arguments[argument_name]) &&
                  (skip_visible || (a = Warden.visible_entry?(:visible_argument?, a, context, warden)))
                  return a
                end
              end
              nil
            end
          end
        end

        module FieldConfigured
          def arguments(context = GraphQL::Query::NullContext.instance, _require_defined_arguments = nil)
            own_arguments = super
            if @resolver_class
              inherited_arguments = @resolver_class.field_arguments(context)
              if !own_arguments.empty?
                if !inherited_arguments.empty?
                  inherited_arguments.merge(own_arguments)
                else
                  own_arguments
                end
              else
                inherited_arguments
              end
            else
              own_arguments
            end
          end

          def any_arguments?
            super || (@resolver_class && @resolver_class.any_field_arguments?)
          end

          def all_argument_definitions
            if @resolver_class
              all_defns = {}
              @resolver_class.all_field_argument_definitions.each do |arg_defn|
                key = arg_defn.graphql_name
                case (current_value = all_defns[key])
                when nil
                  all_defns[key] = arg_defn
                when Array
                  current_value << arg_defn
                when GraphQL::Schema::Argument
                  all_defns[key] = [current_value, arg_defn]
                else
                  raise "Invariant: Unexpected argument definition, #{current_value.class}: #{current_value.inspect}"
                end
              end
              all_defns.merge!(own_arguments)
              all_defns = all_defns.values
              all_defns.flatten!
              all_defns
            else
              super
            end
          end
        end

        def all_argument_definitions
          if !own_arguments.empty?
            all_defns = own_arguments.values
            all_defns.flatten!
            all_defns
          else
            EmptyObjects::EMPTY_ARRAY
          end
        end

        # **Returns**
        #
        # - `GraphQL::Schema::Argument, nil` — Argument defined on this thing, fetched by name.
        #
        # :call-seq:
        #   get_argument(argument_name, context:) -> GraphQL::Schema::Argument | nil
        def get_argument(argument_name, context = GraphQL::Query::NullContext.instance)
          warden = Warden.from_context(context)
          if (arg_config = own_arguments[argument_name]) && ((context.respond_to?(:types) && context.types.is_a?(GraphQL::Schema::Visibility::Profile)) || (visible_arg = Warden.visible_entry?(:visible_argument?, arg_config, context, warden)))
            visible_arg || arg_config
          elsif defined?(@resolver_class) && @resolver_class
            @resolver_class.get_field_argument(argument_name, context)
          else
            nil
          end
        end

        # **Parameters**
        #
        # - `new_arg_class` (`Class`) — A class to use for building argument definitions
        #
        # :call-seq:
        #   argument_class(Class new_arg_class)
        def argument_class(new_arg_class = nil)
          self.class.argument_class(new_arg_class)
        end

        # **Yields:** [Interpreter::Arguments, Execution::Lazy<Interpreter::Arguments>]
        #
        # **Parameters**
        #
        # - `values` (`Hash<String, Object>`)
        # - `context` (`GraphQL::Query::Context`)
        #
        # **Returns**
        #
        # - `Interpreter::Arguments, Execution::Lazy<Interpreter::Arguments>`
        def coerce_arguments(parent_object, values, context, &block) # :nodoc:
          # Cache this hash to avoid re-merging it
          arg_defns = context.types.arguments(self)
          total_args_count = arg_defns.size

          finished_args = nil
          prepare_finished_args = -> {
            if total_args_count == 0
              finished_args = GraphQL::Execution::Interpreter::Arguments::EMPTY
              if block_given?
                block.call(finished_args)
              end
            else
              argument_values = {}
              resolved_args_count = 0
              raised_error = false
              arg_defns.each do |arg_defn|
                context.dataloader.append_job do
                  begin
                    arg_defn.coerce_into_values(parent_object, values, context, argument_values)
                  rescue GraphQL::ExecutionError, GraphQL::UnauthorizedError => err
                    raised_error = true
                    finished_args = err
                    if block_given?
                      block.call(finished_args)
                    end
                  end

                  resolved_args_count += 1
                  if resolved_args_count == total_args_count && !raised_error
                    finished_args = context.schema.after_any_lazies(argument_values.values) {
                      GraphQL::Execution::Interpreter::Arguments.new(
                        argument_values: argument_values,
                      )
                    }
                    if block_given?
                      block.call(finished_args)
                    end
                  end
                end
              end
            end
          }

          if block_given?
            prepare_finished_args.call
            nil
          else
            # This API returns eagerly, gotta run it now
            context.dataloader.run_isolated(&prepare_finished_args)
            finished_args
          end
        end

        # Usually, this is validated statically by RequiredArgumentsArePresent,
        # but not for directives.
        # TODO apply static validations on schema definitions?
        def validate_directive_argument(arg_defn, value)
          # this is only implemented on directives.
          nil
        end

        module HasDirectiveArguments
          def validate_directive_argument(arg_defn, value)
            if value.nil? && arg_defn.type.non_null?
              raise ArgumentError, "#{arg_defn.path} is required, but no value was given"
            end
          end
        end

        def arguments_statically_coercible?
          if defined?(@arguments_statically_coercible) && !@arguments_statically_coercible.nil?
            @arguments_statically_coercible
          else
            @arguments_statically_coercible = all_argument_definitions.all?(&:statically_coercible?)
          end
        end

        module ArgumentClassAccessor
          def argument_class(new_arg_class = nil)
            if new_arg_class
              @argument_class = new_arg_class
            elsif defined?(@argument_class) && @argument_class
              @argument_class
            else
              superclass.respond_to?(:argument_class) ? superclass.argument_class : GraphQL::Schema::Argument
            end
          end
        end

        module ArgumentObjectLoader
          # Look up the corresponding object for a provided ID.
          # By default, it uses Relay-style [Schema.object_from_id](rdoc-ref:Schema.object_from_id),
          # override this to find objects another way.
          #
          # **Parameters**
          #
          # - `type` (`Class, Module`) — A GraphQL type definition
          # - `id` (`String`) — A client-provided to look up
          # - `context` (`GraphQL::Query::Context`) — the current context
          #
          # :call-seq:
          #   object_from_id(Class | Module type, String id, GraphQL::Query::Context context)
          def object_from_id(type, id, context)
            context.schema.object_from_id(id, context)
          end

          def load_application_object(argument, id, context)
            # See if any object can be found for this ID
            if id.nil?
              return nil
            end
            object_from_id(argument.loads, id, context)
          end

          def load_and_authorize_application_object(argument, id, context)
            loaded_application_object = load_application_object(argument, id, context)
            authorize_application_object(argument, id, context, loaded_application_object)
          end

          def authorize_application_object(argument, id, context, loaded_application_object)
            context.query.after_lazy(loaded_application_object) do |application_object|
              if application_object.nil?
                err = GraphQL::LoadApplicationObjectFailedError.new(context: context, argument: argument, id: id, object: application_object)
                application_object = load_application_object_failed(err)
              end
              # Double-check that the located object is actually of this type
              # (Don't want to allow arbitrary access to objects this way)
              if application_object.nil?
                nil
              else
                arg_loads_type = argument.loads
                maybe_lazy_resolve_type = context.schema.resolve_type(arg_loads_type, application_object, context)
                context.query.after_lazy(maybe_lazy_resolve_type) do |resolve_type_result|
                  if resolve_type_result.is_a?(Array) && resolve_type_result.size == 2
                    application_object_type, application_object = resolve_type_result
                  else
                    application_object_type = resolve_type_result
                    # application_object is already assigned
                  end

                  passes_possible_types_check = if context.types.loadable?(arg_loads_type, context)
                    if arg_loads_type.kind.abstract?
                      # This union/interface is used in `loads:` but not otherwise visible to this query
                      context.types.loadable_possible_types(arg_loads_type, context).include?(application_object_type)
                    else
                      true
                    end
                  else
                    context.types.possible_types(arg_loads_type).include?(application_object_type)
                  end
                  if !passes_possible_types_check
                    err = GraphQL::LoadApplicationObjectFailedError.new(context: context, argument: argument, id: id, object: application_object)
                    application_object = load_application_object_failed(err)
                  end

                  if application_object.nil?
                    nil
                  else
                    # This object was loaded successfully
                    # and resolved to the right type,
                    # now apply the `.authorized?` class method if there is one
                    context.query.after_lazy(application_object_type.authorized?(application_object, context)) do |authed|
                      if authed
                        application_object
                      else
                        err = GraphQL::UnauthorizedError.new(
                          object: application_object,
                          type: application_object_type,
                          context: context,
                        )
                        if self.respond_to?(:unauthorized_object)
                          err.set_backtrace(caller)
                          unauthorized_object(err)
                        else
                          raise err
                        end
                      end
                    end
                  end
                end
              end
            end
          end

          # Called when an argument's `loads:` configuration fails to fetch an application object.
          # By default, this method raises the given error, but you can override it to handle failures differently.
          #
          # **API:** public
          #
          # **Parameters**
          #
          # - `err` (`GraphQL::LoadApplicationObjectFailedError`) — The error that occurred
          #
          # **Returns**
          #
          # - `Object, nil` — If a value is returned, it will be used instead of the failed load
          #
          # :call-seq:
          #   load_application_object_failed(GraphQL::LoadApplicationObjectFailedError err) -> Object | nil
          def load_application_object_failed(err)
            raise err
          end
        end

        NO_ARGUMENTS =  GraphQL::EmptyObjects::EMPTY_HASH
        def own_arguments
          @own_arguments || NO_ARGUMENTS
        end
      end
    end
  end
end
