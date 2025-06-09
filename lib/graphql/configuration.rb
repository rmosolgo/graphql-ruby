# lib/graphql/configuration.rb
module GraphQL
  class Configuration
    class << self
      def relay_node_id_type
        @relay_node_id_type ||= GraphQL::Types::ID
        @relay_node_id_type = @relay_node_id_type.constantize if @relay_node_id_type.is_a?(String)
        @relay_node_id_type
      end


      def relay_node_id_type=(scalar)
        @relay_node_id_type = scalar
      end
    end
  end
end
