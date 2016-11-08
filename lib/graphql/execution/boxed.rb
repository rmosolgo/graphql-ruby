module GraphQL
  module Execution
    class Boxed
      def self.unbox(val)
        b = Unbox.unbox_in_place(val)
        Unbox.deep_sync(b)
      end

      def initialize(boxed_value = nil, &get_value_func)
        if boxed_value
          @get_value_func = ->{ boxed_value.value }
        else
          @get_value_func = get_value_func
        end
        @resolved = false
      end

      def value
        if !@resolved
          @resolved = true
          @value = @get_value_func.call
        end
        @value
      end

      def then(&block)
        @then = self.class.new {
          next_val = block.call(value)
        }
      end
    end

    module Unbox
      def self.unbox_in_place(value)
        boxes = []

        each_box(value) do |obj, key, value|
          inner_b = value.then do |inner_v|
            obj[key] = inner_v
            unbox_in_place(inner_v)
          end
          boxes.push(inner_b)
        end

        Boxed.new { boxes.map(&:value) }
      end

      def self.each_box(value, &block)
        case value
        when Hash
          value.each do |k, v|
            if v.is_a?(Boxed)
              yield(value, k, v)
            else
              each_box(v, &block)
            end
          end
        when Array
          value.each_with_index do |v, i|
            if v.is_a?(Boxed)
              yield(value, i, v)
            else
              each_box(v, &block)
            end
          end
        end
      end

      def self.deep_sync(val)
        case val
        when Boxed
          deep_sync(val.value)
        when Array
          val.each { |v| deep_sync(v) }
        when Hash
          val.each { |k, v| deep_sync(v) }
        end
      end
    end
  end
end
