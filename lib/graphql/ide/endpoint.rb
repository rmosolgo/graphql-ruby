module GraphQL
  module IDE
    class Endpoint
      EDITORS = {
        'playground' => File.expand_path('./app/views/graphql/ide/application/playground.html.erb', __dir__),
        'graphiql' => File.expand_path('./app/views/graphql/ide/application/graphiql.html.erb', __dir__)
      }.freeze

      def self.params_from_env(env, view_context: nil)
        mount_params = env['action_dispatch.request.path_parameters']

        params = {
          editor: mount_params.fetch(:editor, 'playground'),
          options: mount_params.fetch(:options, {}),
          extras: {}
        }

        if mount_params.fetch(:csrf, false)
          raise 'View Context not present. Only use this with GraphQL::IDE::Engine' unless view_context
          params[:extras][:csrf_token] = view_context.form_authenticity_token
        end

        params
      end

      def self.get_view(editor)
        editor = EDITORS.fetch(editor.to_s, nil)
        raise ArgumentError, "IDE #{editor} not found. Only #{EDITORS.keys.join("and ")} are supported." unless editor
        ERB.new(File.read(editor))
      end

      def call(env, view_context: nil)
        editor, options, extras = self.class.params_from_env(env, view_context: nil).values_at(:editor, :options, :extras)
        view = self.class.get_view(editor)

        [200, { 'Content-Type' => 'text/html' }, [view.result(binding)]]
      end
    end
  end
end
