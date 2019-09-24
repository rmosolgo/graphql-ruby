module GraphQL
  module IDE
    class ApplicationController < ActionController::Base
      protect_from_forgery with: :exception

      def show
        editor, options, extras = Endpoint.params_from_env(request.env, view_context: view_context)
          .values_at(:editor, :options, :extras)

        render editor, locals: { options: options, extras: extras }
      end
    end
  end
end
