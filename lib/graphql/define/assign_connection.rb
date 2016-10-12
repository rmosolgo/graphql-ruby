module GraphQL
  module Define
    module AssignConnection
      ### Ruby 1.9.3 unofficial support
      # def self.call(type_defn, *field_args, max_page_size: nil, **field_kwargs, &field_block)
      def self.call(type_defn, options = {}, &field_block)
        max_page_size = options.fetch(:max_page_size, nil)
        field_args = options.delete_if { |k, _| k == :max_page_size }

        ### Ruby 1.9.3 unofficial support
        # underlying_field = GraphQL::Define::AssignObjectField.call(type_defn, *field_args, **field_kwargs, &field_block)
        underlying_field = GraphQL::Define::AssignObjectField.call(type_defn, field_args, &field_block)
        connection_field = GraphQL::Relay::ConnectionField.create(underlying_field, max_page_size: max_page_size)
        type_defn.fields[underlying_field.name] = connection_field
      end
    end
  end
end
