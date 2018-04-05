# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      # DSL methods shared by lots of things in the GraphQL Schema.
      # @api private
      # @see Classes that extend this, eg {GraphQL::Schema::Object}
      module BaseDSLMethods
        # Call this with a new name to override the default name for this schema member; OR
        # call it without an argument to get the name of this schema member
        #
        # The default name is the Ruby constant name,
        # without any namespaces and with any `-Type` suffix removed
        # @param new_name [String]
        # @return [String]
        def graphql_name(new_name = nil)
          if new_name
            @graphql_name = new_name
          else
            overridden_graphql_name || name.split("::").last.sub(/Type\Z/, "")
          end
        rescue
          binding.pry
        end

        # Just a convenience method to point out that people should use graphql_name instead
        def name(new_name = nil)
          return super() if new_name.nil?

          fail(
            "The new name override method is `graphql_name`, not `name`. Usage: "\
            "graphql_name \"#{new_name}\""
          )
        end

        # Call this method to provide a new description; OR
        # call it without an argument to get the description
        # @param new_description [String]
        # @return [String]
        def description(new_description = nil)
          if new_description
            @description = new_description
          else
            @description || (superclass.respond_to?(:description) ? superclass.description : nil)
          end
        end

        # @return [Boolean] If true, this object is part of the introspection system
        def introspection(new_introspection = nil)
          if !new_introspection.nil?
            @introspection = new_introspection
          else
            @introspection || (superclass.respond_to?(:introspection) ? superclass.introspection : false)
          end
        end

        # The mutation this type was derived from, if it was derived from a mutation
        # @return [Class]
        def mutation(mutation_class = nil)
          if mutation_class
            @mutation = mutation_class
          end
          @mutation
        end

        # @return [GraphQL::BaseType] Convert this type to a legacy-style object.
        def to_graphql
          raise NotImplementedError
        end

        # @return [ListTypeProxy] Make a list-type representation of this type
        def to_list_type
          ListTypeProxy.new(self)
        end

        # @return [NonNullTypeProxy] Make a non-null-type representation of this type
        def to_non_null_type
          NonNullTypeProxy.new(self)
        end

        protected

        def overridden_graphql_name
          # Use respond_to?(method, true) so that it will find this protected method
          @graphql_name || (superclass.respond_to?(:overridden_graphql_name, true) ? superclass.overridden_graphql_name : nil)
        end
      end
    end
  end
end
