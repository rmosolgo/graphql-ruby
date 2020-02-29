# frozen_string_literal: true

module GraphQL
  module Pagination
    # A schema-level connection wrapper manager.
    #
    # Attach as a plugin.
    #
    # @example Using new default connections
    #   class MySchema < GraphQL::Schema
    #     use GraphQL::Pagination::Connections
    #   end
    #
    # @example Adding a custom wrapper
    #   class MySchema < GraphQL::Schema
    #     use GraphQL::Pagination::Connections
    #     connections.add(MyApp::SearchResults, MyApp::SearchResultsConnection)
    #   end
    #
    # @example Removing default connection support for arrays (they can still be manually wrapped)
    #   class MySchema < GraphQL::Schema
    #     use GraphQL::Pagination::Connections
    #     connections.delete(Array)
    #   end
    #
    # @see {Schema.connections}
    class Connections
      class ImplementationMissingError < GraphQL::Error
      end

      def self.use(schema_defn)
        if schema_defn.is_a?(Class)
          schema_defn.connections = self.new(schema: schema_defn)
        else
          # Unwrap a `.define` object
          schema_defn = schema_defn.target
          schema_defn.connections = self.new(schema: schema_defn)
          schema_defn.class.connections = schema_defn.connections
        end
      end

      def initialize(schema:)
        @schema = schema
        @wrappers = {}
        add_default
      end

      def add(nodes_class, implementation)
        @wrappers[nodes_class] = implementation
      end

      def delete(nodes_class)
        @wrappers.delete(nodes_class)
      end

      def all_wrappers
        all_wrappers = {}
        @schema.ancestors.reverse_each do |schema_class|
          if schema_class.respond_to?(:connections) && (c = schema_class.connections)
            all_wrappers.merge!(c.wrappers)
          end
        end
        all_wrappers
      end

      # Used by the runtime to wrap values in connection wrappers.
      # @api Private
      def wrap(field, object, arguments, context, wrappers: all_wrappers)
        impl = nil

        object.class.ancestors.each { |cls|
          impl = wrappers[cls]
          break if impl
        }

        if impl.nil?
          raise ImplementationMissingError, "Couldn't find a connection wrapper for #{object.class} during #{field.path} (#{object.inspect})"
        end

        impl.new(
          object,
          context: context,
          max_page_size: field.max_page_size || context.schema.default_max_page_size,
          first: arguments[:first],
          after: arguments[:after],
          last: arguments[:last],
          before: arguments[:before],
        )
      end

      protected

      attr_reader :wrappers

      private

      def add_default
        add(Array, Pagination::ArrayConnection)

        if defined?(ActiveRecord::Relation)
          add(ActiveRecord::Relation, Pagination::ActiveRecordRelationConnection)
        end

        if defined?(Sequel::Dataset)
          add(Sequel::Dataset, Pagination::SequelDatasetConnection)
        end

        if defined?(Mongoid::Criteria)
          add(Mongoid::Criteria, Pagination::MongoidRelationConnection)
        end

        # Mongoid 5 and 6
        if defined?(Mongoid::Relations::Targets::Enumerable)
          add(Mongoid::Relations::Targets::Enumerable, Pagination::MongoidRelationConnection)
        end

        # Mongoid 7
        if defined?(Mongoid::Association::Referenced::HasMany::Targets::Enumerable)
          add(Mongoid::Association::Referenced::HasMany::Targets::Enumerable, Pagination::MongoidRelationConnection)
        end
      end
    end
  end
end
