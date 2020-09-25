# frozen_string_literal.rb

module GraphQL
  class Dataloader
    # @example Load belongs-to associations in a batch
    #   ActiveRecordAssociation.load(Post, :author, post_1)
    #   ActiveRecordAssociation.load(Post, :author, post_2)
    class ActiveRecordAssociation < Dataloader::Source
      def initialize(model, association_name)
        @model = model
        @association_name = association_name
      end

      def load(record)
        # return early if this association is already loaded
        if record.association(@association_name).loaded?
          GraphQL::Execution::Lazy.new { record.public_send(@association_name) }
        else
          super
        end
      end

      def perform(records)
        ::ActiveRecord::Associations::Preloader.new.preload(records, @association_name)
        records.each { |record|
          fulfill(record, record.public_send(@association_name))
        }
      end
    end
  end
end
