# frozen_string_literal: true
require "graphql/dataloader/source"

module GraphQL
  class Dataloader
    class ActiveRecordSource < GraphQL::Dataloader::Source
      def initialize(model_class, find_by: model_class.primary_key)
        @model_class = model_class
        @find_by = find_by
        @find_by_many = find_by.is_a?(Array)
        if @find_by_many
          @type_for_column = @find_by.map { |fb| @model_class.type_for_attribute(fb) }
        else
          @type_for_column = @model_class.type_for_attribute(@find_by)
        end
      end

      def result_key_for(requested_key)
        normalize_fetch_key(requested_key)
      end

      def normalize_fetch_key(requested_key)
        if @find_by_many
          requested_key.each_with_index.map do |k, idx|
            @type_for_column[idx].cast(k)
          end
        else
          @type_for_column.cast(requested_key)
        end
      end

      def fetch(record_ids)
        records = @model_class.where(@find_by => record_ids)
        record_lookup = {}
        if @find_by_many
          records.each do |r|
            key = @find_by.map { |fb| r.public_send(fb) }
            record_lookup[key] = r
          end
        else
          records.each { |r| record_lookup[r.public_send(@find_by)] = r }
        end
        record_ids.map { |id| record_lookup[id] }
      end
    end
  end
end
