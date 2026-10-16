module GraphQL
  module Tracing
    module PerfettoTrace
      class TrackEvent
        class Type
          TYPE_SLICE_BEGIN = Integer
          TYPE_SLICE_END = Integer
          TYPE_INSTANT = Integer
          TYPE_COUNTER = Integer
        end
      end

      class TracePacket; end
      class InternedData; end
      class EventCategory; end
      class DebugAnnotationName; end
      class InternedString; end
      class EventName; end
      class DebugAnnotation; end
      class TrackDescriptor
        class ChildTracksOrdering
          CHRONOLOGICAL = Integer
        end
      end
    end
  end
end
