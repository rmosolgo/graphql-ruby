module GraphQL
  class Schema
    class Mask
      extend Forwardable

      def_delegators :@schema, :execute

      def initialize(schema:, &block)
        @schema = schema.dup
        @schema.instance_variable_set(:@mask, self)
        @filter = block
      end

      def visible?(member)
        !hidden?(member)
      end

      def hidden?(member)
        !!@filter.call(member)
      end

      def hidden_field?(field_defn)
        hidden?(field_defn) || hidden?(field_defn.type.unwrap)
      end

      def visible_field?(field_defn)
        !hidden_field?(field_defn)
      end

      def hidden_type?(type_defn)
        hidden?(type_defn)
      end

      def visible_type?(type_defn)
        !hidden_type?(type_defn)
      end

      # A Mask implementation that shows everything as visible
      module NullMask
        module_function
        def visible?(member)
          true
        end

        def hidden?(member)
          false
        end

        def hidden_field?(field)
          false
        end

        def visible_field?(field)
          true
        end

        def hidden_type?(field)
          false
        end

        def visible_type?(field)
          true
        end
      end
    end
  end
end
