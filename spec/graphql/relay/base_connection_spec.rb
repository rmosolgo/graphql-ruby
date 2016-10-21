require 'spec_helper'

describe GraphQL::Relay::BaseConnection do

  describe ".connection_for_nodes" do

    it "resolves most specific connection type" do
      class SpecialArray < Array; end
      class SpecialArrayConnection < GraphQL::Relay::BaseConnection; end
      GraphQL::Relay::BaseConnection.register_connection_implementation(SpecialArray, SpecialArrayConnection)

      nodes = SpecialArray.new

      GraphQL::Relay::BaseConnection.connection_for_nodes(nodes)
        .must_equal SpecialArrayConnection
    end

  end
end
