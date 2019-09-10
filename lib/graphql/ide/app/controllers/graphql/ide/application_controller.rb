module GraphQL
  module IDE
    class ApplicationController < ActionController::Base
      protect_from_forgery with: :exception

      def show
        ide = Parameters.from_request_env(request.env, view_context: self.view_context)

        render ide.editor, locals: { ide: ide }
      end
    end
  end
end
