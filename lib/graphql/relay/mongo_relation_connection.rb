# frozen_string_literal: true
module GraphQL
  module Relay
    # A connection implementation to expose MongoDB collection objects.
    # It works for:
    # - `Mongoid::Criteria`
    class MongoRelationConnection < RelationConnection
      private

      def relation_offset(relation)
        relation.options.skip
      end

      def relation_limit(relation)
        relation.options.limit
      end

      def relation_count(relation)
        # Must perform query (hence #to_a) to count results https://jira.mongodb.org/browse/MONGOID-2325
        relation.to_a.count
      end

      def limit_nodes(sliced_nodes, limit)
        if limit == 0
          if sliced_nodes.respond_to?(:none) # added in Mongoid 4.0
            sliced_nodes.without_options.none
          else
            sliced_nodes.where(id: nil) # trying to simulate #none for 3.1.7
          end
        else
          sliced_nodes.limit(limit)
        end
      end
    end

    if defined?(Mongoid::Criteria)
      BaseConnection.register_connection_implementation(Mongoid::Criteria, MongoRelationConnection)
    end

    # Mongoid 5 and 6
    if defined?(Mongoid::Relations::Targets::Enumerable)
      BaseConnection.register_connection_implementation(Mongoid::Relations::Targets::Enumerable, MongoRelationConnection)
    end

    # Mongoid 7
    if defined?(Mongoid::Association::Referenced::HasMany::Targets::Enumerable)
      BaseConnection.register_connection_implementation(Mongoid::Association::Referenced::HasMany::Targets::Enumerable, MongoRelationConnection)
    end
  end
end
