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
      delete "/traces/delete_all", to: "traces#delete_all", as: :traces_delete_all
    end

    class ApplicationController < ActionController::Base
      protect_from_forgery with: :exception
      prepend_view_path(File.join(__FILE__, "../dashboard/views"))

      content_security_policy do |policy|
        policy.default_src(:self) if policy.default_src(*policy.default_src).blank?
        policy.connect_src(:self) if policy.connect_src(*policy.connect_src).blank?
        policy.base_uri(:none) if policy.base_uri(*policy.base_uri).blank?
        policy.font_src(:self) if policy.font_src(*policy.font_src).blank?
        policy.img_src(:self, :data) if policy.img_src(*policy.img_src).blank?
        policy.object_src(:none) if policy.object_src(*policy.object_src).blank?
        policy.script_src(:self) if policy.script_src(*policy.script_src).blank?
        policy.style_src(:self) if policy.style_src(*policy.style_src).blank?
        policy.form_action(:self) if policy.form_action(*policy.form_action).blank?
        policy.frame_ancestors(:none) if policy.frame_ancestors(*policy.frame_ancestors).blank?
      end

      def schema_class
        @schema_class ||= begin
          schema_param = request.query_parameters["schema"] || params[:schema]
          case schema_param
          when Class
            schema_param
          when String
            schema_param.constantize
          else
            raise "Missing `params[:schema]`, please provide a class or string to `mount GraphQL::Dashboard, schema: ...`"
          end
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
        @perfetto_sampler_installed = !!schema_class.perfetto_sampler
        if @perfetto_sampler_installed
          @last = params[:last]&.to_i || 50
          @before = params[:before]&.to_i
          @traces = schema_class.perfetto_sampler.traces(last: @last, before: @before)
        end
      end

      def show
        trace = schema_class.perfetto_sampler.find_trace(params[:id].to_i)
        send_data(trace.trace_data)
      end

      def destroy
        schema_class.perfetto_sampler.delete_trace(params[:id])
        head :no_content
      end

      def destroy_all
        schema_class.perfetto_sampler.delete_all_traces
        head :no_content
      end
    end

    class StaticsController < ApplicationController
      skip_after_action :verify_same_origin_request
      # Use an explicit list of files to avoid any chance of reading other files from disk
      STATICS = {}

      [
        "icon.png",
        "header-icon.png",
        "dashboard.css",
        "dashboard.js",
        "bootstrap-5.3.3.min.css",
        "bootstrap-5.3.3.min.js",
      ].each do |static_file|
        STATICS[static_file] = File.expand_path("../dashboard/statics/#{static_file}", __FILE__)
      end

      def show
        expires_in 1.year, public: true
        if (filepath = STATICS[params[:id]])
          render file: filepath
        else
          head :not_found
        end
      end
    end
  end
end

# Rails expects the engine to be called `Graphql::Dashboard`,
# but `GraphQL::Dashboard` is consistent with this gem's naming.
# So define both constants to refer to the same class.
GraphQL::Dashboard = Graphql::Dashboard
