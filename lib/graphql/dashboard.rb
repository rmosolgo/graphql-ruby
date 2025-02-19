# frozen_string_literal: true
require 'rails/engine'

module Graphql
  class Dashboard < Rails::Engine
    engine_name "graphql_dashboard"
    isolate_namespace(Graphql::Dashboard)
    routes.draw do
      root "landings#show"
      resources :traces, only: [:index, :show]
    end

    class ApplicationController < ActionController::Base
      protect_from_forgery with: :exception
      prepend_view_path(File.join(__FILE__, "../dashboard/views"))

      helper_method def schema_class
        params[:schema]
      end
    end

    class LandingsController < ApplicationController
      def show
      end
    end

    class TracesController < ApplicationController
      def index
        @perfetto_sampler = schema_class.perfetto_sampler
      end

      def show
        trace = schema_class.perfetto_sampler.find_trace(params[:id].to_i)
        send_data(trace.trace_data)
      end
    end
  end
end


GraphQL::Dashboard = Graphql::Dashboard
