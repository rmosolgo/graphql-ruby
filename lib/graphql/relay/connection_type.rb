module GraphQL
  module Relay
    # An ObjectType which also stores its {#connection_class}
    class ConnectionType < GraphQL::ObjectType
      defined_by_config :name, :fields, :interfaces
      # @return [Class] A subclass of {BaseConnection}
      attr_accessor :connection_class
    end
  end
end
