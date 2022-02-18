module GraphQL
  class Schema
    class FieldResolver
      attr_reader :field_name, :resolver_class, :resolver_method, :object_method, :hash_keys, :dig_keys

      # @param field [GraphQL::Schema:Field] The field being resolved
      # @param field_name [Symbol, String] The underscore-cased version of this field name (and the default method to resolve)
      # @param resolver_class [Class] The {Schema::Resolver} which the field will  was derived from.
      # @param resolver_method [Symbol] The method on the type to call to resolve this field (defaults to `field_name`)
      # @param object_method [Symbol] The method on the object to call to resolve this field (defaults to `field_name`)
      # @param hash_key [Symbol] The key on the hash object to call to resolve this field
      # @param dig_keys [Array<String, Symbol>] The nested hash keys to lookup on the underlying hash to resolve this field using dig
      def initialize(
        field:,
        field_name:,
        resolver_class: nil,
        resolver_method: nil,
        object_method: nil,
        hash_key: nil,
        dig_keys: nil
      )
        @field = field
        @field_name = field_name.to_sym
        @resolver_class = resolver_class
        @resolver_method = resolver_method.to_sym
        @object_method = object_method.to_sym
        @hash_key = hash_key.to_sym
        @dig_keys = dig_keys
      end

      def resolve(object, query_context, **kwargs)
        if @resolver_class
          object = object.object if object.is_a? GraphQL::Schema::Object
          object = @resolver_class.new(object: object, context: query_context, field: @field)
        end

        case resolver_type
        when :resolver_class
        when :resolver_method
        when :object_method
        when :field_name
          method_or_key = @resolver_method || @object_method || @field_name
          if object.respond_to?(method_or_key)
            if kwargs.any?
              object.public_send(method_or_key, **kwargs)
            else
              object.public_send(method_or_key)
            end
          elsif object.is_a?(Hash)
            if object.key?(method_or_key)
              object[method_or_key]
            elsif object.key?(method_or_key.to_s)
              object[method_or_key.to_s]
            end
          end
        when :hash_key
          if object.is_a?(Hash)
            if object.key?(@hash_key)
              object[@hash_key]
            else
              object[@hash_key.to_s]
            end
          end
        when :dig_keys
          object.dig(*@dig_keys) if object.repond_to?(:dig)
        else
          raise
        end
      end

      def resolver_type
        if @resolver_class
          :resolver_class
        elsif @resolver_method
          :resolver_method
        elsif @object_method
          :object_method
        elsif @hash_key
          :hash_key
        elsif @dig_keys
          :dig_keys
        else
          :field_name
        end
      end
    end
  end
end
