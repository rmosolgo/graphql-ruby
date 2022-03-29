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
        end

        # @see {GraphQL::Schema::Argument#initialize} for parameters
        # @return [GraphQL::Schema::Argument] An instance of {argument_class}, created from `*args`
        def argument(*args, **kwargs, &block)
          kwargs[:owner] = self
          loads = kwargs[:loads]
          if loads
            name = args[0]
            name_as_string = name.to_s

            inferred_arg_name = case name_as_string
            when /_id$/
              name_as_string.sub(/_id$/, "").to_sym
            when /_ids$/
              name_as_string.sub(/_ids$/, "")
                .sub(/([^s])$/, "\\1s")
                .to_sym
            else
              name
            end

            kwargs[:as] ||= inferred_arg_name
          end
          arg_defn = self.argument_class.new(*args, **kwargs, &block)
          add_argument(arg_defn)

          if self.is_a?(Class) && !method_defined?(:"load_#{arg_defn.keyword}")
            method_owner = if self < GraphQL::Schema::InputObject || self < GraphQL::Schema::Directive
              "self."
            elsif self < GraphQL::Schema::Resolver
              ""
            else
              raise "Unexpected argument owner: #{self}"
            end
            if loads && arg_defn.type.list?
              class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{method_owner}load_#{arg_defn.keyword}(values, context = nil)
                argument = get_argument("#{arg_defn.graphql_name}")
                (context || self.context).schema.after_lazy(values) do |values2|
                  GraphQL::Execution::Lazy.all(values2.map { |value| load_application_object(argument, value, context || self.context) })
                end
              end
              RUBY
            elsif loads
              class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{method_owner}load_#{arg_defn.keyword}(value, context = nil)
                argument = get_argument("#{arg_defn.graphql_name}")
                load_application_object(argument, value, context || self.context)
              end
              RUBY
            else
              class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{method_owner}load_#{arg_defn.keyword}(value, _context = nil)
                value
              end
              RUBY
            end
          end
          arg_defn
        end

        # Register this argument with the class.
        # @param arg_defn [GraphQL::Schema::Argument]
        # @return [GraphQL::Schema::Argument]
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

        # @return [Hash<String => GraphQL::Schema::Argument] Arguments defined on this thing, keyed by name. Includes inherited definitions
        def arguments(context = GraphQL::Query::NullContext)
          inherited_arguments = if self.is_a?(Class) && superclass.respond_to?(:arguments)
            superclass.arguments(context)
          elsif defined?(@resolver_class) && @resolver_class
            @resolver_class.field_arguments(context)
          else
            nil
          end
          # Local definitions override inherited ones
          if own_arguments.any?
            own_arguments_that_apply = {}
            own_arguments.each do |name, args_entry|
              if (visible_defn = Warden.visible_entry?(:visible_argument?, args_entry, context))
                own_arguments_that_apply[visible_defn.graphql_name] = visible_defn
              end
            end
          end

          if inherited_arguments
            if own_arguments_that_apply
              inherited_arguments.merge(own_arguments_that_apply)
            else
              inherited_arguments
            end
          else
            # might be nil if there are actually no arguments
            own_arguments_that_apply || own_arguments
          end
        end

        def all_argument_definitions
          if self.is_a?(Class)
            all_defns = {}
            ancestors.reverse_each do |ancestor|
              if ancestor.respond_to?(:own_arguments)
                all_defns.merge!(ancestor.own_arguments)
              end
            end
          elsif defined?(@resolver_class) && @resolver_class
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
          else
            all_defns = own_arguments
          end
          all_defns = all_defns.values
          all_defns.flatten!
          all_defns
        end

        # @return [GraphQL::Schema::Argument, nil] Argument defined on this thing, fetched by name.
        def get_argument(argument_name, context = GraphQL::Query::NullContext)
          warden = Warden.from_context(context)
          if !self.is_a?(Class)
            if (arg_config = own_arguments[argument_name]) && (visible_arg = Warden.visible_entry?(:visible_argument?, arg_config, context, warden))
              visible_arg
            elsif defined?(@resolver_class) && @resolver_class
              @resolver_class.get_field_argument(argument_name, context)
            else
              nil
            end
          else
            for ancestor in ancestors
              if ancestor.respond_to?(:own_arguments) &&
                (a = ancestor.own_arguments[argument_name]) &&
                (a = Warden.visible_entry?(:visible_argument?, a, context, warden))
                return a
              end
            end
            nil
          end
        end

        # @param new_arg_class [Class] A class to use for building argument definitions
        def argument_class(new_arg_class = nil)
          self.class.argument_class(new_arg_class)
        end

        # @api private
        # If given a block, it will eventually yield the loaded args to the block.
        #
        # If no block is given, it will immediately dataload (but might return a Lazy).
        #
        # @param values [Hash<String, Object>]
        # @param context [GraphQL::Query::Context]
        # @yield [Interpreter::Arguments, Execution::Lazy<Interpeter::Arguments>]
        # @return [Interpreter::Arguments, Execution::Lazy<Interpeter::Arguments>]
        def coerce_arguments(parent_object, values, context, &block)
          # Cache this hash to avoid re-merging it
          arg_defns = self.arguments(context)
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
              arg_defns.each do |arg_name, arg_defn|
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
          if arg_defn.owner.is_a?(Class) && arg_defn.owner < GraphQL::Schema::Directive
            if value.nil? && arg_defn.type.non_null?
              raise ArgumentError, "#{arg_defn.path} is required, but no value was given"
            end
          end
        end

        def arguments_statically_coercible?
          return @arguments_statically_coercible if defined?(@arguments_statically_coercible)

          @arguments_statically_coercible = all_argument_definitions.all?(&:statically_coercible?)
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
          # By default, it uses Relay-style {Schema.object_from_id},
          # override this to find objects another way.
          #
          # @param type [Class, Module] A GraphQL type definition
          # @param id [String] A client-provided to look up
          # @param context [GraphQL::Query::Context] the current context
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
            context.schema.after_lazy(loaded_application_object) do |application_object|
              if application_object.nil?
                err = GraphQL::LoadApplicationObjectFailedError.new(argument: argument, id: id, object: application_object)
                load_application_object_failed(err)
              end
              # Double-check that the located object is actually of this type
              # (Don't want to allow arbitrary access to objects this way)
              resolved_application_object_type = context.schema.resolve_type(argument.loads, application_object, context)
              context.schema.after_lazy(resolved_application_object_type) do |application_object_type|
                possible_object_types = context.warden.possible_types(argument.loads)
                if !possible_object_types.include?(application_object_type)
                  err = GraphQL::LoadApplicationObjectFailedError.new(argument: argument, id: id, object: application_object)
                  load_application_object_failed(err)
                else
                  # This object was loaded successfully
                  # and resolved to the right type,
                  # now apply the `.authorized?` class method if there is one
                  context.schema.after_lazy(application_object_type.authorized?(application_object, context)) do |authed|
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

          def load_application_object_failed(err)
            raise err
          end
        end

        NO_ARGUMENTS = {}.freeze
        def own_arguments
          @own_arguments || NO_ARGUMENTS
        end
      end
    end
  end
end
