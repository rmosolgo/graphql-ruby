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
        load_value(parsed_obj)
      end

      # @param value [Object] A parsed JSON object
      # @return [Object] An object that load Golbal::Identification recursive
      def load_value(value)
        if value.is_a?(Array)
          value.map{|item| load_value(item)}
        elsif value.is_a?(Hash)
          if value.size == 1 && value.key?(GLOBALID_KEY)
            GlobalID::Locator.locate(value[GLOBALID_KEY])
          else
            Hash[value.map{|k, v| [k, load_value(v)]}]
          end
        else
          value
        end
      end

      # @param obj [Object] Some subscription-related data to dump
      # @return [String] The stringified object
      def dump(obj)
        JSON.generate(dump_value(obj), quirks_mode: true)
      end

      # @param obj [Object] Some subscription-related data to dump
      # @return [Object] The object that converted Global::Identification
      def dump_value(obj)
        if obj.is_a?(Array)
          obj.map{|item| dump_value(item)}
        elsif obj.is_a?(Hash)
          Hash[obj.map{|k, v| [k, dump_value(v)]}]
        elsif obj.respond_to?(:to_gid_param)
          {GLOBALID_KEY => obj.to_gid_param}
        else
          obj
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
