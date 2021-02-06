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
        # @return [GraphQL::Schema::Argument] An instance of {arguments_class}, created from `*args`
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
        end

        # Register this argument with the class.
        # @param arg_defn [GraphQL::Schema::Argument]
        # @return [GraphQL::Schema::Argument]
        def add_argument(arg_defn)
          @own_arguments ||= {}
          own_arguments[arg_defn.name] = arg_defn
          arg_defn
        end

        # @return [Hash<String => GraphQL::Schema::Argument] Arguments defined on this thing, keyed by name. Includes inherited definitions
        def arguments
          inherited_arguments = ((self.is_a?(Class) && superclass.respond_to?(:arguments)) ? superclass.arguments : nil)
          # Local definitions override inherited ones
          if inherited_arguments
            inherited_arguments.merge(own_arguments)
          else
            own_arguments
          end
        end

        # @return [GraphQL::Schema::Argument, nil] Argument defined on this thing, fetched by name.
        def get_argument(argument_name)
          a = own_arguments[argument_name]

          if a || !self.is_a?(Class)
            a
          else
            for ancestor in ancestors
              if ancestor.respond_to?(:own_arguments) && a = ancestor.own_arguments[argument_name]
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
          arg_defns = self.arguments
          total_args_count = arg_defns.size

          if total_args_count == 0
            final_args = GraphQL::Execution::Interpreter::Arguments::EMPTY
            if block_given?
              block.call(final_args)
              nil
            else
              final_args
            end
          else
            finished_args = nil
            argument_values = {}
            resolved_args_count = 0
            raised_error = false
            arg_defns.each do |arg_name, arg_defn|
              context.dataloader.append_job do
                begin
                  arg_defn.coerce_into_values(parent_object, values, context, argument_values)
                rescue GraphQL::ExecutionError, GraphQL::UnauthorizedError => err
                  raised_error = true
                  if block_given?
                    block.call(err)
                  else
                    finished_args = err
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

            if block_given?
              nil
            else
              # This API returns eagerly, gotta run it now
              context.dataloader.run
              finished_args
            end
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

          @arguments_statically_coercible = arguments.each_value.all?(&:statically_coercible?)
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

          def load_application_object(argument, lookup_as_type, id, context)
            # See if any object can be found for this ID
            if id.nil?
              return nil
            end
            loaded_application_object = object_from_id(lookup_as_type, id, context)
            context.schema.after_lazy(loaded_application_object) do |application_object|
              if application_object.nil?
                err = GraphQL::LoadApplicationObjectFailedError.new(argument: argument, id: id, object: application_object)
                load_application_object_failed(err)
              end
              # Double-check that the located object is actually of this type
              # (Don't want to allow arbitrary access to objects this way)
              resolved_application_object_type = context.schema.resolve_type(lookup_as_type, application_object, context)
              context.schema.after_lazy(resolved_application_object_type) do |application_object_type|
                possible_object_types = context.warden.possible_types(lookup_as_type)
                if !possible_object_types.include?(application_object_type)
                  err = GraphQL::LoadApplicationObjectFailedError.new(argument: argument, id: id, object: application_object)
                  load_application_object_failed(err)
                else
                  # This object was loaded successfully
                  # and resolved to the right type,
                  # now apply the `.authorized?` class method if there is one
                  if (class_based_type = application_object_type.type_class)
                    context.schema.after_lazy(class_based_type.authorized?(application_object, context)) do |authed|
                      if authed
                        application_object
                      else
                        raise GraphQL::UnauthorizedError.new(
                          object: application_object,
                          type: class_based_type,
                          context: context,
                        )
                      end
                    end
                  else
                    application_object
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
