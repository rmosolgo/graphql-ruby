module GraphQL
  class Schema
    # A helper to ensure `object` implements the concept `as`
    class ImplementationValidator
      attr_reader :object, :errors, :implementation_as
      def initialize(object, as:, errors:)
        @object = object
        @implementation_as = as
        @errors = errors
      end

      # Ensure the object responds to `method_name`.
      # If `block_given?`, yield the return value of that method
      # If provided, use `as` in the error message, overriding class-level `as`.
      def must_respond_to(method_name, args: [], as: nil)
        local_as = as || implementation_as
        method_signature = "##{method_name}(#{args.join(", ")})"
        if !object.respond_to?(method_name)
          errors << "#{object.to_s} must respond to #{method_signature} to be a #{local_as}"
        elsif block_given?
          return_value = object.public_send(method_name)
          if return_value.nil?
            errors << "#{object.to_s} must return a value for #{method_signature} to be a #{local_as}"
          else
            yield(return_value)
          end
        end
      end
    end
  end
end
