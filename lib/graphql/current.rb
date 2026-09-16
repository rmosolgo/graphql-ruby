# frozen_string_literal: true

module GraphQL
  # This module exposes Fiber-level runtime information.
  #
  # It won't work across unrelated fibers, although it will work in child Fibers.
  #
  # **Examples**
  #
  # **Example: Setting Up ActiveRecord::QueryLogs**
  #
  # ```ruby
  # config.active_record.query_log_tags = [
  #   :namespaced_controller,
  #   :action,
  #   :job,
  #   # ...
  #   {
  #     # GraphQL runtime info:
  #     current_graphql_operation: -> { GraphQL::Current.operation_name },
  #     current_graphql_field: -> { GraphQL::Current.field&.path },
  #     current_dataloader_source: -> { GraphQL::Current.dataloader_source_class },
  #     # ...
  #   },
  # ]
  # ```
  module Current
    # **Returns**
    #
    # - `String, nil` — Comma-joined operation names for the currently-running `Execution::Multiplex`. `nil` if all operations are anonymous.
    #
    # :call-seq:
    #   operation_name() -> String | nil
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

    # See [Schema::Member::HasPath#path](rdoc-ref:GraphQL::Schema::Member::HasPath#path) for a string identifying this field
    #
    # **Returns**
    #
    # - `GraphQL::Field, nil` — The currently-running field, if there is one.
    #
    # :call-seq:
    #   field() -> GraphQL::Field | nil
    def self.field
      if (interpreter_info = Fiber[:__graphql_runtime_info])
        interpreter_info.values&.first&.current_field
      elsif (field = Fiber[:__graphql_current_field])
        field
      else
        nil
      end
    end

    # **Returns**
    #
    # - `Class, nil` — The currently-running [Dataloader::Source](rdoc-ref:Dataloader::Source) class, if there is one.
    #
    # :call-seq:
    #   dataloader_source_class() -> Class | nil
    def self.dataloader_source_class
      Fiber[:__graphql_current_dataloader_source]&.class
    end

    # **Returns**
    #
    # - `GraphQL::Dataloader::Source, nil` — The currently-running source, if there is one
    #
    # :call-seq:
    #   dataloader_source() -> GraphQL::Dataloader::Source | nil
    def self.dataloader_source
      Fiber[:__graphql_current_dataloader_source]
    end
  end
end
