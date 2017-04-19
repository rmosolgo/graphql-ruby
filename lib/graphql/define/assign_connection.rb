# frozen_string_literal: true
module GraphQL
  module Define
    module AssignConnection
      def self.call(type_defn, *field_args, max_page_size: nil, **field_kwargs, &field_block)
        underlying_field = GraphQL::Define::AssignObjectField.call(type_defn, *field_args, **field_kwargs, &field_block)
        underlying_field.connection_max_page_size = max_page_size
        underlying_field.connection = true
        type_defn.fields[underlying_field.name] = underlying_field
      end
    end
  end
end
