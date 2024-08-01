# frozen_string_literal: true

module GraphQL
  module Current
    # @return [String, nil] Comma-joined operation names for the currently-running {Multiplex}. `nil` if all operations are anonymous.
    def self.operation_name
      if (m = Fiber[:__graphql_current_multiplex])
        m.context[:__graphql_current_operation_name] ||= begin
          names = m.queries.map { |q| q.selected_operation_name }
          if names.all?(&:nil?)
            nil
          else
            names.join(",")
          end
        end
      else
        nil
      end
    end

    # @return [String, nil] The `Type.fieldName` string for the currently-running field, if there is one.
    def self.field_path
      Thread.current[:__graphql_runtime_info]&.values&.first&.current_field&.path
    end

    # @return [Class, nil] The currently-running {Dataloader::Source} class, if there is one.
    def self.dataloader_source_class
      Fiber[:__graphql_current_dataloader_source]&.class
    end
  end
end
