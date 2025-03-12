# frozen_string_literal: true
module Graphql
  class Dashboard < Rails::Engine
    module OperationStore
      class ClientsController < Dashboard::ApplicationController
        before_action :check_installed

        def index
          @order_by = params[:order_by] || "name"
          @order_dir = params[:order_dir].presence || "asc"
          clients_page = schema_class.operation_store.all_clients(
            page: params[:page].presence || 1,
            per_page: params[:per_page].presence || 25,
            order_by: @order_by,
            order_dir: @order_dir,
          )

          @clients_page = clients_page
        end

        def create
        end

        def show
        end

        def update
        end

        def destroy
        end

        private

        def check_installed
          if !schema_class.respond_to?(:operation_store) || schema_class.operation_store.nil?
            render "graphql/dashboard/operation_store/not_installed"
          end
        end
      end

      class OperationsController < Dashboard::ApplicationController
      end

      class IndexEntriesController < Dashboard::ApplicationController
      end
    end
  end
end
