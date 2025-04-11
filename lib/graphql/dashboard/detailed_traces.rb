# frozen_string_literal: true
require_relative "./installable"
module Graphql
  class Dashboard < Rails::Engine
    module DetailedTraces
      class TracesController < Graphql::Dashboard::ApplicationController
        include Installable

        def index
          @last = params[:last]&.to_i || 50
          @before = params[:before]&.to_i
          @traces = schema_class.detailed_trace.traces(last: @last, before: @before)
        end

        def show
          trace = schema_class.detailed_trace.find_trace(params[:id].to_i)
          send_data(trace.trace_data)
        end

        def destroy
          schema_class.detailed_trace.delete_trace(params[:id])
          flash[:success] = "Trace deleted."
          head :no_content
        end

        def delete_all
          schema_class.detailed_trace.delete_all_traces
          flash[:success] = "Deleted all traces."
          head :no_content
        end

        private

        def feature_installed?
          !!schema_class.detailed_trace
        end

        INSTALLABLE_COMPONENT_HEADER_HTML = "Detailed traces aren't installed yet."
        INSTALLABLE_COMPONENT_MESSAGE_HTML = <<~HTML.html_safe
          GraphQL-Ruby can instrument production traffic and save tracing artifacts here for later review.
          <br>
          Read more in <a href="https://graphql-ruby.org/queries/tracing#detailed-traces">the detailed tracing docs</a>.
        HTML
      end
    end
  end
end
