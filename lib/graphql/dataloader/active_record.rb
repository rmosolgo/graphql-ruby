# frozen_string_literal.rb

module GraphQL
  class Dataloader
    # @example Find a record by ID
    #   GraphQL::Dataloader::ActiveRecord.load(Post, id)
    #
    # @example Find several records by their IDs
    #   GraphQL::Dataloader::ActiveRecord.load_all(Post, [id1, id2, id3])
    class ActiveRecord < Dataloader::Source
      def initialize(model)
        @model = model
      end

      def perform(ids)
        records = @model.where(id: ids)
        ids.each do |id|
          record = records.find { |r| r.id == id }
          fulfill(id, record)
        end
      end
    end
  end
end
