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

      def self.load(association_name, record)
        super(record.class, association_name, record)
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
        if ::ActiveRecord::Associations::Preloader.method_defined?(:call)
          # After Rails 6.2, Preloader's API changes to `new(**kwargs).call`
          ::ActiveRecord::Associations::Preloader
            .new(records: records, associations: @association_name, scope: nil)
            .call
        else
          ::ActiveRecord::Associations::Preloader
            .new
            .preload(records, @association_name)
        end
        records.each { |record|
          fulfill(record, record.public_send(@association_name))
        }
      end
    end
  end
end
