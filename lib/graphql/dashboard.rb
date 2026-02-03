# frozen_string_literal: true
require 'rails/engine'
require 'action_controller'
module Graphql
  # `GraphQL::Dashboard` is a `Rails::Engine`-based dashboard for viewing metadata about your GraphQL schema.
  #
  # Pass the class name of your schema when mounting it.
  # @see GraphQL::Tracing::DetailedTrace DetailedTrace for viewing production traces in the Dashboard
  #
  # @example Mounting the Dashboard in your app
  #   mount GraphQL::Dashboard, at: "graphql_dashboard", schema: "MySchema"
  #
  # @example Authenticating the Dashboard with HTTP Basic Auth
  #   # config/initializers/graphql_dashboard.rb
  #   GraphQL::Dashboard.middleware.use(Rack::Auth::Basic) do |username, password|
  #     # Compare the provided username/password to an application setting:
  #     ActiveSupport::SecurityUtils.secure_compare(Rails.application.credentials.graphql_dashboard_username, username) &&
  #       ActiveSupport::SecurityUtils.secure_compare(Rails.application.credentials.graphql_dashboard_username, password)
  #   end
  #
  # @example Custom Rails authentication
  #   # config/initializers/graphql_dashboard.rb
  #   ActiveSupport.on_load(:graphql_dashboard_application_controller) do
  #     # context here is GraphQL::Dashboard::ApplicationController
  #
  #     before_action do
  #       raise ActionController::RoutingError.new('Not Found') unless current_user&.admin?
  #     end
  #
  #     def current_user
  #       # load current user
  #     end
  #   end
  #
  class Dashboard < Rails::Engine
    engine_name "graphql_dashboard"
    isolate_namespace(Graphql::Dashboard)

    autoload :ApplicationController, "graphql/dashboard/application_controller"
    autoload :LandingsController, "graphql/dashboard/landings_controller"
    autoload :StaticsController, "graphql/dashboard/statics_controller"

    routes do
      root "landings#show"
      resources :statics, only: :show, constraints: { id: /[0-9A-Za-z\-.]+/ }

      namespace :detailed_traces do
        resources :traces, only: [:index, :show, :destroy] do
          collection do
            delete :delete_all, to: "traces#delete_all", as: :delete_all
          end
        end
      end

      namespace :limiters do
        resources :limiters, only: [:show, :update], param: :name
      end

      namespace :operation_store do
        resources :clients, param: :name do
          resources :operations, param: :digest, only: [:index] do
            collection do
              get :archived, to: "operations#index", archived_status: :archived, as: :archived
              post :archive, to: "operations#update", modification: :archive, as: :archive
              post :unarchive, to: "operations#update", modification: :unarchive, as: :unarchive
            end
          end
        end

        resources :operations, param: :digest, only: [:index, :show] do
          collection do
            get :archived, to: "operations#index", archived_status: :archived, as: :archived
            post :archive, to: "operations#update", modification: :archive, as: :archive
            post :unarchive, to: "operations#update", modification: :unarchive, as: :unarchive
          end
        end
        resources :index_entries, only: [:index, :show], param: :name, constraints: { name: /[A-Za-z0-9_.]+/}
      end

      namespace :subscriptions do
        resources :topics, only: [:index, :show], param: :name, constraints: { name: /.*/ }
        resources :subscriptions, only: [:show], constraints: { id: /[a-zA-Z0-9\-]+/ }
        post "/subscriptions/clear_all", to: "subscriptions#clear_all", as: :clear_all
      end

      ApplicationController.include(Dashboard.routes.url_helpers)
    end
  end
end

require 'graphql/dashboard/detailed_traces'
require 'graphql/dashboard/limiters'
require 'graphql/dashboard/operation_store'
require 'graphql/dashboard/subscriptions'

# Rails expects the engine to be called `Graphql::Dashboard`,
# but `GraphQL::Dashboard` is consistent with this gem's naming.
# So define both constants to refer to the same class.
GraphQL::Dashboard = Graphql::Dashboard

ActiveSupport.run_load_hooks(:graphql_dashboard_application_controller, GraphQL::Dashboard::ApplicationController)
