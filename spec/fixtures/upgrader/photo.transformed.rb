module Platform
  module Objects
    class Photo < Platform::Objects::Base
      field :caption, String, null: true

      def caption
        @object.caption
      end
    end
  end
end
