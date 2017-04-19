# frozen_string_literal: true
module GraphQL
  class Schema
    # A two-level map with fields as the last values.
    # The first level is type names, which point to a second map.
    # The second level is field names, which point to fields.
    #
    # The catch is, the fields in this map _may_ have been modified by being instrumented.
    class InstrumentedFieldMap
      # Build a map using types from `schema` and instrumenters in `field_instrumenters`
      # @param schema [GraphQL::Schema]
      # @param field_instrumenters [Array<#instrument(type, field)>]
      def initialize(schema, field_instrumenters)
        @storage = Hash.new { |h, k| h[k] = {} }
        schema.types.each do |type_name, type|
          if type.kind.fields?
            type.all_fields.each do |field_defn|
              instrumented_field_defn = field_instrumenters.reduce(field_defn) do |defn, inst|
                inst.instrument(type, defn)
              end
              self.set(type.name, field_defn.name, instrumented_field_defn)
            end
          end
        end
      end

      def set(type_name, field_name, field)
        @storage[type_name][field_name] = field
      end

      def get(type_name, field_name)
        @storage[type_name][field_name]
      end

      def get_all(type_name)
        @storage[type_name]
      end
    end
  end
end
