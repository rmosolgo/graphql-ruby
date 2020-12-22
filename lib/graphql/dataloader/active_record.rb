# frozen_string_literal.rb

module GraphQL
  class Dataloader
    # @example Find a record by ID
    #   GraphQL::Dataloader::ActiveRecord.load(Post, id)
    #
    # @example Find several records by their IDs
    #   GraphQL::Dataloader::ActiveRecord.load_all(Post, [id1, id2, id3])
    class ActiveRecord < Dataloader::Source
      def initialize(model, column: model.primary_key)
        @model = model
        @column = column
        @column_type = model.type_for_attribute(@column)
      end

      # Override this to make sure that the values always match type (eg, turn `"1"` into `1`)
      def load(column_value)
        casted_value = if @column_type.respond_to?(:type_cast)
          @column_type.type_cast(column_value)
        elsif @column_type.respond_to?(:type_cast_from_user)
          @column_type.type_cast_from_user(column_value)
        else
          @column_type.cast(column_value)
        end

        super(casted_value)
      end

      def perform(column_values)
        records = @model.where(@column => column_values)
        column_values.each do |v|
          record = records.find { |r| r.public_send(@column) == v }
          fulfill(v, record)
        end
      end
    end
  end
end
