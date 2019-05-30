module GraphQL
  module RailsIntegration
    module SerializeAsJSON
      def as_json(*)
        to_h
      end
    end
  end
end
