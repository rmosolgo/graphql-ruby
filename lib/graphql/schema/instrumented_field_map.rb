module GraphQL
  class Schema
    # A two-level map with fields as the last values.
    # The first level is type names, which point to a second map.
    # The second level is field names, which point to fields.
    #
    # The catch is, the fields in this map _may_ have been modified by being instrumented.
    class InstrumentedFieldMap
      def initialize(schema)
        @storage = Hash.new { |h, k| h[k] = {} }
      end

      def set(type_name, field_name, field)
        @storage[type_name][field_name] = field
      end

      def get(type_name, field_name)
        type = @storage[type_name]
        type && type[field_name]
      end
    end
  end
end
