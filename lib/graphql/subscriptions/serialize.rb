# frozen_string_literal: true
# test_via: ../subscriptions.rb
module GraphQL
  class Subscriptions
    # Serialization helpers for passing subscription data around.
    # @api private
    module Serialize
      GLOBALID_KEY = "__gid__"
      module_function

      # @param str [String] A serialized object from {.dump}
      # @return [Object] An object equivalent to the one passed to {.dump}
      def load(str)
        parsed_obj = JSON.parse(str)
        if parsed_obj.is_a?(Hash) && parsed_obj.size == 1 && parsed_obj.key?(GLOBALID_KEY)
          GlobalID::Locator.locate(parsed_obj[GLOBALID_KEY])
        else
          parsed_obj
        end
      end

      # @param obj [Object] Some subscription-related data to dump
      # @return [String] The stringified object
      def dump(obj)
        if obj.respond_to?(:to_gid_param)
          JSON.dump(GLOBALID_KEY => obj.to_gid_param)
        else
          JSON.generate(obj, quirks_mode: true)
        end
      end

      # This is for turning objects into subscription scopes.
      # It's a one-way transformation, can't reload this :'(
      # @param obj [Object]
      # @return [String]
      def dump_recursive(obj)
        case
        when obj.is_a?(Array)
          obj.map { |i| dump_recursive(i) }.join(':')
        when obj.is_a?(Hash)
          obj.map { |k, v| "#{dump_recursive(k)}:#{dump_recursive(v)}" }.join(":")
        when obj.respond_to?(:to_gid_param)
          obj.to_gid_param
        when obj.respond_to?(:to_param)
          obj.to_param
        else
          obj.to_s
        end
      end
    end
  end
end
