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
            if int.is_a?(Module)
              # Include the methods here,
              # `.fields` will use the inheritance chain
              # to find inherited fields
              include(int)
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

        # Include legacy-style interfaces, too
        def fields
          all_fields = super
          interfaces.each do |int|
            if int.is_a?(GraphQL::InterfaceType)
              int_f = {}
              int.fields.each do |name, legacy_field|
                int_f[name] = field_class.from_options(name, field: legacy_field)
              end
              all_fields = int_f.merge(all_fields)
            end
          end
          all_fields
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
            field_defn = field_inst.to_graphql
            obj_type.fields[field_defn.name] = field_defn
          end

          obj_type.metadata[:type_class] = self

          obj_type
        end

        def kind
          GraphQL::TypeKinds::OBJECT
        end
      end
    end
  end
end
