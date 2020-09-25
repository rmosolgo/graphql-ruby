# frozen_string_literal.rb
require "net/http"

module GraphQL
  class Dataloader
    # This source performs an HTTP GET for each given URL, then returns the parsed JSON body.
    #
    # In reality, this source should check `response.content_type` and
    # handle non-success responses in some way, but it doesn't.
    #
    # For your own application, you'd probably want to batch calls to external APIs in semantically useful ways,
    # where IDs or call parameters are grouped, then merged in to an API call to a known URL.
    class Http < Dataloader::Source
      def perform(urls)
        urls.each do |url|
          uri = URI(url)
          response = Net::HTTP.get_response(uri)
          parsed_body = if response.body.empty?
            nil
          else
            JSON.parse(response.body)
          end
          fulfill(url, parsed_body)
        end
      end
    end
  end
end
