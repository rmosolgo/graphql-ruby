require 'active_support/concern'

module GraphQL::Callable
  extend ActiveSupport::Concern
  included do
    class << self
      def calls
        @calls ||= []
      end

      def parent_calls
        superclass == Object ? [] : (superclass.calls  + superclass.parent_calls)
      end

      def all_calls
        calls + parent_calls
      end

      def find_call(name)
        all_calls.find { |c| c[:name] == name }
      end

      def call(name, lambda)
        calls << {
          name: name.to_s,
          lambda: lambda,
        }
      end
    end

    def apply_calls(initial_value, call_array)
      val = initial_value
      call_array.each do |call|
        registered_call = self.class.find_call(call.identifier)
        if registered_call.nil?
          raise "Call not found: #{self.class.name}##{call.identifier}"
        end
        val = registered_call[:lambda].call(val, *call.arguments)
      end
      val
    end
  end
end