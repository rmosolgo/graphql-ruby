# frozen_string_literal: true

module GraphQL
  class Schema
    class Object < GraphQL::Schema::Member
      attr_reader :object

      def initialize(object, context)
        @object = object
        @context = context
      end
      extend GraphQL::Schema::Member::HasFields
      field_class GraphQL::Schema::Field

      class << self
        def implements(*new_interfaces)
          new_interfaces.each do |int|
            if int.is_a?(Class) && int < GraphQL::Schema::Interface
              # Add the graphql field defns
              int.fields.each do |field|
                add_field(field)
              end
              # And call the implemented hook
              int.apply_implemented(self)
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

          fields.each do |field_inst|
            field_defn = field_inst.graphql_definition
            obj_type.fields[field_defn.name] = field_defn
          end

          obj_type.metadata[:object_class] = self

          obj_type
        end

        def global_id_field(field_name)
          field field_name, "ID", null: false, resolve: GraphQL::Relay::GlobalIdResolve.new(type: self)
        end
      end
    end
  end
end
