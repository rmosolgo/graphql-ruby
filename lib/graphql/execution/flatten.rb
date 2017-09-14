# frozen_string_literal: true
module GraphQL
  module Execution
    # Starting from a root context,
    # create a hash out of the context tree.
    # @api private
    module Flatten
      def self.call(ctx)
        flatten(ctx)
      end

      class << self
        private

        def flatten(obj)
          case obj
          when Hash
            flattened = {}
            obj.each do |key, val|
              flattened[key] = flatten(val)
            end
            flattened
          when Array
            obj.map { |v| flatten(v) }
          when Query::Context::SharedMethods
            if obj.invalid_null?
              nil
            elsif obj.skipped? && obj.value.empty?
              nil
            else
              flatten(obj.value)
            end
          else
            obj
          end
        end
      end
    end
  end
end
