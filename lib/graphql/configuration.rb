# frozen_string_literal: true

module GraphQL
  # `GraphQL::Configuration` is a class that holds configuration settings.
  #
  # I don't expect this class to live long and a better comment will be coming if needed...
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
