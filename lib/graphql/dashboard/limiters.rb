# frozen_string_literal: true
require_relative "./installable"
module Graphql
  class Dashboard < Rails::Engine
    module Limiters
      class LimitersController < Dashboard::ApplicationController
        include Installable
        FALLBACK_CSP_NONCE_GENERATOR = ->(_req) { SecureRandom.hex(32) }

        def show
          name = params[:name]
          @title = case name
          when "runtime"
            "Runtime Limiter"
          when "active_operations"
            "Active Operation Limiter"
          when "mutations"
            "Mutation Limiter"
          else
            raise ArgumentError, "Unknown limiter name: #{name}"
          end

          limiter = limiter_for(name)
          if limiter.nil?
            @install_path = "http://graphql-ruby.org/limiters/#{name}"
          else
            @chart_mode = params[:chart] || "day"
            @current_soft = limiter.soft_limit_enabled?
            @histogram = limiter.dashboard_histogram(@chart_mode)

            # These configs may have already been defined by the application; provide overrides here if not.
            request.content_security_policy_nonce_generator ||= FALLBACK_CSP_NONCE_GENERATOR
            nonce_dirs = request.content_security_policy_nonce_directives || []
            if !nonce_dirs.include?("style-src")
              nonce_dirs += ["style-src"]
              request.content_security_policy_nonce_directives = nonce_dirs
            end
            @csp_nonce = request.content_security_policy_nonce
          end
        end

        def update
          name = params[:name]
          limiter = limiter_for(name)
          if limiter
            limiter.toggle_soft_limit
            flash[:success] = if limiter.soft_limit_enabled?
              "Enabled soft limiting -- over-limit traffic will be logged but not rejected."
            else
              "Disabled soft limiting -- over-limit traffic will be rejected."
            end
          else
            flash[:warning] = "No limiter configured for #{name.inspect}"
          end

          redirect_to graphql_dashboard.limiters_limiter_path(name, chart: params[:chart])
        end

        private

        def limiter_for(name)
          case name
          when "runtime"
            schema_class.enterprise_runtime_limiter
          when "active_operations"
            schema_class.enterprise_active_operation_limiter
          when "mutations"
            schema_class.enterprise_mutation_limiter
          else
            raise ArgumentError, "Unknown limiter: #{name}"
          end
        end

        def feature_installed?
          defined?(GraphQL::Enterprise::Limiter) &&
            (
              schema_class.enterprise_active_operation_limiter ||
              schema_class.enterprise_runtime_limiter ||
              (schema_class.respond_to?(:enterprise_mutation_limiter) && schema_class.enterprise_mutation_limiter)
            )
        end


        INSTALLABLE_COMPONENT_HEADER_HTML = "Rate limiters aren't installed on this schema yet."
        INSTALLABLE_COMPONENT_MESSAGE_HTML = <<-HTML.html_safe
          Check out the docs to get started with GraphQL-Enterprise's
          <a href="https://graphql-ruby.org/limiters/runtime.html">runtime limiter</a> or
          <a href="https://graphql-ruby.org/limiters/active_operations.html">active operation limiter</a>.
        HTML
      end
    end
  end
end
