# frozen_string_literal: true
if defined?(ActionCable)
  module ActionCable
    # A stub for testing Channels
    # based on https://medium.com/@tomekw/unit-testing-actioncable-channels-with-rspec-ca67ca6834af
    class TestConnection
      attr_reader :identifiers, :logger, :transmissions

      def initialize(identifiers_hash = {})
        @identifiers = identifiers_hash.keys
        @logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(StringIO.new))
        @transmissions = []
        # This is an equivalent of providing `identified_by :identifier_key` in ActionCable::Connection::Base subclass
        identifiers_hash.each do |identifier, value|
          define_singleton_method(identifier) do
            value
          end
        end
      end

      def transmit(data)
        @transmissions << data
      end
    end
  end
end
