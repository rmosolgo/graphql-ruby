# frozen_string_literal: true

module GraphQL
  module Current
    def self.operation_name
      Thread.current[:__graphql_runtime_info]&.keys&.first&.selected_operation_name
    end

    def self.field_path
      Thread.current[:__graphql_runtime_info]&.values&.first&.current_field&.path
    end

    def self.dataloader_source_class
      Fiber[:__graphql_current_dataloader_source]&.class
    end
  end
end
