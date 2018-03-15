# frozen_string_literal: true
module GraphQL
  class Schema
    class Member
      module HasArguments
        def self.included(cls)
          cls.extend(ArgumentClassAccessor)
        end

        def self.extended(cls)
          cls.extend(ArgumentClassAccessor)
        end

        # @see {GraphQL::Schema::Argument#initialize} for parameters
        # @return [GraphQL::Schema::Argument] An instance of {arguments_class}, created from `*args`
        def argument(*args, **kwargs)
          kwargs[:owner] = self
          arg_defn = self.argument_class.new(*args, **kwargs)
          own_arguments[arg_defn.name] = arg_defn
        end

        # @return [Hash<String => GraphQL::Schema::Argument] Arguments defined on this thing, keyed by name. Includes inherited definitions
        def arguments
          inherited_arguments = ((self.is_a?(Class) && superclass <= GraphQL::Schema::Member::HasArguments) ? superclass.arguments : {})
          # Local definitions override inherited ones
          inherited_arguments.merge(own_arguments)
        end

        # @param new_arg_class [Class] A class to use for building argument definitions
        def argument_class(new_arg_class = nil)
          self.class.argument_class(new_arg_class)
        end

        module ArgumentClassAccessor
          def argument_class(new_arg_class = nil)
            if new_arg_class
              @argument_class = new_arg_class
            else
              @argument_class || GraphQL::Schema::Argument
            end
          end
        end

        private

        def own_arguments
          @own_arguments ||= {}
        end
      end
    end
  end
end
