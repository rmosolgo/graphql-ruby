require 'set'

module GraphQL
  module IDE
    class Parameters
      def self.from_request_env(env, view_context: nil)
        mount_params = env['action_dispatch.request.path_parameters']

        editor = mount_params.fetch(:editor, 'playground')
        options = mount_params.fetch(:options, {})
        headers = options.fetch(:headers).merge({
          'Content-Type' => 'application/json'
        })
        add_csrf = mount_params.fetch(:csrf, false)

        if add_csrf
          raise 'View Context not present. Only use this with GraphQL::IDE::Engine' unless view_context
          headers = headers.merge('X-CSRF-Token' => view_context.form_authenticity_token)
        end

        new(editor: editor, headers: headers, options: options)
      end

      attr_reader :editor, :title, :options, :headers
      def initialize(editor:, options:, headers:)
        @editor = editor
        @options = options
        @headers = headers
      end
    end
  end
end
