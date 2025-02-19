# frozen_string_literal: true
require 'rails/engine'

module Graphql
  class Dashboard < Rails::Engine
    engine_name "graphql_dashboard"
    isolate_namespace(Graphql::Dashboard)
    routes.draw do
      root "landings#show"
      resources :statics, only: :show, constraints: { id: /[0-9A-Za-z\-.]+/ }
      resources :traces, only: [:index, :show, :destroy]
    end

    class ApplicationController < ActionController::Base
      protect_from_forgery with: :exception
      prepend_view_path(File.join(__FILE__, "../dashboard/views"))

      def schema_class
        @schema_class ||= case params[:schema]
        when Class
          params[:schema]
        when String
          params[:schema].constantize
        else
          raise "Missing `params[:schema]`, please provide a class or string to `mount GraphQL::Dashboard, schema: ...`"
        end
      end
      helper_method :schema_class
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

      def destroy
        schema_class.perfetto_sampler.delete_trace(params[:id])
        head :no_content
      end
    end

    class StaticsController < ApplicationController
      STATICS = {
        "icon.png" => File.expand_path("../dashboard/statics/icon.png", __FILE__),
        "header-icon.png" => File.expand_path("../dashboard/statics/header-icon.png", __FILE__),
      }
      def show
        expires_in 1.year, public: true
        if (filepath = STATICS[params[:id]])
          render file: filepath
        else
          head :no_content
        end
      end
    end
  end
end


GraphQL::Dashboard = Graphql::Dashboard
