# frozen_string_literal: true
require "graphql/dataloader/source"
require "graphql/dataloader/active_record_source"

module GraphQL
  class Dataloader
    class ActiveRecordAssociationSource < GraphQL::Dataloader::Source
      RECORD_SOURCE_CLASS = ActiveRecordSource

      def initialize(association, scope = nil)
        @association = association
        @scope = scope
      end

      def self.batch_key_for(association, scope = nil)
        if scope
          [association, scope.to_sql]
        else
          [association]
        end
      end

      def load(record)
        if (assoc = record.association(@association)).loaded?
          assoc.target
        else
          super
        end
      end

      def fetch(records)
        record_classes = Set.new.compare_by_identity
        associated_classes = Set.new.compare_by_identity
        scoped_fetch = !@scope.nil?
        records.each do |record|
          if scoped_fetch
            assoc = record.association(@association)
            assoc.reset
          end
          if record_classes.add?(record.class)
            reflection = record.class.reflect_on_association(@association)
            if !reflection.polymorphic? && reflection.klass
              associated_classes.add(reflection.klass)
            end
          end
        end

        available_records = []
        associated_classes.each do |assoc_class|
          already_loaded_records = dataloader.with(RECORD_SOURCE_CLASS, assoc_class).results.values
          available_records.concat(already_loaded_records)
        end

        ::ActiveRecord::Associations::Preloader.new(records: records, associations: @association, available_records: available_records, scope: @scope).call

        loaded_associated_records = records.map { |r|
          assoc = r.association(@association)
          lar = assoc.target
          if scoped_fetch
            assoc.reset
          end
          lar
        }

        if !scoped_fetch
          # Don't cache records loaded via scope because they might have reduced `SELECT`s
          # Could check .select_values here?
          records_by_model = {}
          loaded_associated_records.flatten.each do |record|
            if record
              updates = records_by_model[record.class] ||= {}
              updates[record.id] = record
            end
          end
          records_by_model.each do |model_class, updates|
            dataloader.with(RECORD_SOURCE_CLASS, model_class).merge(updates)
          end
        end

        loaded_associated_records
      end
    end
  end
end
