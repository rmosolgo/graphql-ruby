module GraphQL
  module Execution
    # Contains the list field's ExecFrame
    # And the enumerator which is being mapped
    # - {ExecStream#enumerator} is an Enumerator which yields `item, idx`
    # - {ExecStream#frame} is the {ExecFrame} for the list selection (where `@stream` was present)
    # - {ExecStream#type} is the inner type of the list (the item's type)
    class ExecStream
      attr_reader :enumerator, :frame, :type
      def initialize(enumerator:, frame:, type:)
        @enumerator = enumerator
        @frame = frame
        @type = type
      end
    end
  end
end
