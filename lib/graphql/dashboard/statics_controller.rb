# frozen_string_literal: true
module Graphql
  class Dashboard < Rails::Engine
    class StaticsController < ApplicationController
      skip_after_action :verify_same_origin_request
      # Use an explicit list of files to avoid any chance of reading other files from disk
      STATICS = {}

      [
        "icon.png",
        "header-icon.png",
        "charts.min.css",
        "dashboard.css",
        "dashboard.js",
        "bootstrap-5.3.3.min.css",
        "bootstrap-5.3.3.min.js",
      ].each do |static_file|
        STATICS[static_file] = File.expand_path("../statics/#{static_file}", __FILE__)
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
