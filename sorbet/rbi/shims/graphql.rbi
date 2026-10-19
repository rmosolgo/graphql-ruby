module GraphQL
  module Tracing
    module PerfettoTrace
      class Trace
        def initialize(attrs = nil, **kwargs); end
        def self.encode(message); end
        def self.encode_json(message); end
      end

      class TrackEvent
        def initialize(attrs = nil, **kwargs); end

        class Type
          TYPE_SLICE_BEGIN = Integer
          TYPE_SLICE_END = Integer
          TYPE_INSTANT = Integer
          TYPE_COUNTER = Integer
        end
      end

      class TracePacket
        def initialize(attrs = nil, **kwargs); end
      end
      class InternedData
        def initialize(attrs = nil, **kwargs); end
      end
      class EventCategory
        def initialize(attrs = nil, **kwargs); end
      end
      class DebugAnnotationName
        def initialize(attrs = nil, **kwargs); end
      end
      class InternedString
        def initialize(attrs = nil, **kwargs); end
      end
      class EventName
        def initialize(attrs = nil, **kwargs); end
      end
      class DebugAnnotation
        def initialize(attrs = nil, **kwargs); end
      end
      class TrackDescriptor
        def initialize(attrs = nil, **kwargs); end

        class ChildTracksOrdering
          CHRONOLOGICAL = Integer
        end
      end
    end
  end
end
