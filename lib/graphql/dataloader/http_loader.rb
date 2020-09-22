# frozen_string_literal: true
require "graphql/dataloader/loader"

module GraphQL
  class Dataloader
    class HttpLoader
      def get(url, params: {}, headers: {})
        load(:get, url, params, headers)
      end

      def initalize(context, method, url, headers)
        super
        @url = url
      end

      def perform(values)
      end
    end
  end
end
