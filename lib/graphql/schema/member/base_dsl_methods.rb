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
          case
          when new_name
            @graphql_name = new_name
          when overridden = overridden_graphql_name
            overridden
          else # Fallback to Ruby constant name
            raise NotImplementedError, 'Anonymous class should declare an `graphql_name`' if name.nil?
            
            name.split("::").last.sub(/Type\Z/, "")
          end
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
            @description || find_inherited_method(:description, nil)
          end
        end

        # @return [Boolean] If true, this object is part of the introspection system
        def introspection(new_introspection = nil)
          if !new_introspection.nil?
            @introspection = new_introspection
          else
            @introspection || find_inherited_method(:introspection, false)
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

        def overridden_graphql_name
          @graphql_name || find_inherited_method(:overridden_graphql_name, nil)
        end

        private

        def find_inherited_method(method_name, default_value)
          if self.is_a?(Class)
            superclass.respond_to?(method_name) ? superclass.public_send(method_name) : default_value
          else
            ancestors[1..-1].each do |ancestor|
              if ancestor.respond_to?(method_name)
                return ancestor.public_send(method_name)
              end
            end
            default_value
          end
        end
      end
    end
  end
end
