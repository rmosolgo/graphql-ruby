# frozen_string_literal: true
require "action_controller"

module Graphql
  class Dashboard < Rails::Engine
    class ApplicationController < ActionController::Base
      protect_from_forgery with: :exception
      prepend_view_path(File.expand_path("../views", __FILE__))

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
  end
end

ActiveSupport.run_load_hooks(:graphql_dashboard_application_controller, GraphQL::Dashboard::ApplicationController)
