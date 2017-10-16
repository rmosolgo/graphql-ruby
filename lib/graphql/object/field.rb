# frozen_string_literal: true
# test_via: ../object.rb

module GraphQL
  class Object
    class Field
      def initialize(name, return_type_expr, desc = nil, null: false, deprecation_reason: nil, method: nil, &args_block)
        @name = name.to_s
        @description = desc
        @deprecation_reason = deprecation_reason
        @method = method
        @return_type_expr = return_type_expr
        @return_type_null = null
        @args_block = args_block
      end

      # @return [GraphQL::Field]
      def to_graphql(schema:)
        # read ivars to cope with instance_eval in .define {...}
        field_name = @name
        return_type_expr = @return_type_expr
        return_type_null = @return_type_null
        desc = @description
        depr_reason = @deprecation_reason
        connection = BuildType.to_type_name(return_type_expr).end_with?("Connection")
        method_name = @method || @name.underscore
        args_block = @args_block

        field_defn = GraphQL::Field.define do
          name(field_name)
          type(-> {
            Object::BuildType.parse_type(schema, return_type_expr, null: return_type_null)
          })
          description(desc)
          deprecation_reason(depr_reason)
          resolve(GraphQL::Object::Resolvers::Metadata.new)
          # This no-op strategy raises an error if it's ever called
          target.metadata[:resolve_strategy] = GraphQL::Object::Resolvers::Pending.new
          # This is used during schema boot to check for a method
          target.metadata[:implementation_method_name] = method_name
          # apply this first, so it can be overriden below
          if connection
            FieldProxy.new(self).instance_eval do
              argument :after, "String", "Returns the elements in the list that come after the specified global ID."
              argument :before, "String", "Returns the elements in the list that come before the specified global ID."
              argument :first, "Int", "Returns the first _n_ elements from the list."
              argument :last, "Int", "Returns the last _n_ elements from the list."
            end
          end
          if args_block
            FieldProxy.new(self).instance_eval(&args_block)
          end
        end

        field_defn
      end


      class FieldProxy
        def initialize(defn)
          @defn = defn
        end

        def argument(arg_name, type_expr, desc = nil, null: false, default_value: :__no_default__)
          default_value_was_provided = default_value != :__no_default__
          # Rename to avoid naming conflict below
          provided_default_value = default_value

          @defn.argument do
            name(arg_name.to_s)
            type(-> {
              Object::BuildType.parse_type(schema, type_expr, null: null)
            })
            description(desc)
            if default_value_was_provided
              default_value(provided_default_value)
            end
          end
        end
      end

    end
  end
end
