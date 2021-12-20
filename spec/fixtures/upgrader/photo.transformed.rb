# frozen_string_literal: true
module Platform
  module Objects
    class Photo < Platform::Objects::Base
      field :caption, String

      def caption
        object.caption
      end
    end
  end
end
