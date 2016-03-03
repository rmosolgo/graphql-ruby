module GraphQL
  class Schema
    class EachItemValidator
      def initialize(errors)
        @errors = errors
      end

      def validate(items, as:, must_be:)
        if !items.is_a?(Array)
          @errors << "#{as} must be an Array, not #{items.inspect}"
          return
        else
          invalid_items = items.select {|k| !yield(k) }
          if invalid_items.any?
            @errors << "#{as} must be #{must_be}, but some aren't: #{invalid_items.map(&:to_s).join(", ")}"
          end
        end
      end
    end
  end
end
