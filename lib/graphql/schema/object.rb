# frozen_string_literal: true

module GraphQL
  class Schema
    class Object < GraphQL::Schema::Member
      extend GraphQL::Schema::Member::AcceptsDefinition
      extend GraphQL::Schema::Member::HasFields

      # @return [Object] the application object this type is wrapping
      attr_reader :object

      # @return [GraphQL::Query::Context] the context instance for this query
      attr_reader :context

      def initialize(object, context)
        @object = object
        @context = context
      end

      class << self
        def implements(*new_interfaces)
          new_interfaces.each do |int|
            if int.is_a?(Class) && int < GraphQL::Schema::Interface
              # Add the graphql field defns
              int.fields.each do |name, field|
                own_fields[name] = field
              end
              # And call the implemented hook
              int.implemented(self)
            else
              int.all_fields.each do |f|
                field(f.name, field: f)
              end
            end
          end
          own_interfaces.concat(new_interfaces)
        end

        def interfaces
          own_interfaces + (superclass <= GraphQL::Schema::Object ? superclass.interfaces : [])
        end

        def own_interfaces
          @own_interfaces ||= []
        end

        # @return [GraphQL::ObjectType]
        def to_graphql
          obj_type = GraphQL::ObjectType.new
          obj_type.name = graphql_name
          obj_type.description = description
          obj_type.interfaces = interfaces
          obj_type.introspection = introspection
          obj_type.mutation = mutation

          fields.each do |field_name, field_inst|
            field_defn = field_inst.graphql_definition
            obj_type.fields[field_defn.name] = field_defn
          end

          obj_type.metadata[:type_class] = self

          obj_type
        end
      end
    end
  end
end
