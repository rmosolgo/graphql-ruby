require 'erb'
require 'json'

module GraphQL
  module Endpoints
    class Playground
      INDEX_PAGE = ERB.new(File.read(File.expand_path('../../../playground/index.html.erb', __dir__)))

      def self.call(env)
        playground_options = JSON.generate(env['action_dispatch.request.path_parameters'].fetch(:playground, {}))

        return [200, { 'Content-Type' => 'text/html' }, [INDEX_PAGE.result(binding)]]
      end
    end
  end
end
