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

        def new
          @client = init_client(secret: SecureRandom.hex(32))
        end

        def create
          client_params = params.require(:client).permit(:name, :secret)
          schema_class.operation_store.upsert_client(client_params[:name], client_params[:secret])
          flash[:success] = "Created #{client_params[:name].inspect}"
          redirect_to graphql_dashboard.operation_store_clients_path
        end

        def edit
          @client = schema_class.operation_store.get_client(params[:name])
        end

        def update
          client_name = params[:name]
          client_secret = params.require(:client).permit(:secret)[:secret]
          schema_class.operation_store.upsert_client(client_name, client_secret)
          flash[:success] = "Updated #{client_name.inspect}"
          redirect_to graphql_dashboard.operation_store_clients_path
        end

        def destroy
          client_name = params[:name]
          schema_class.operation_store.delete_client(client_name)
          flash[:success] = "Deleted #{client_name.inspect}"
          redirect_to graphql_dashboard.operation_store_clients_path
        end

        private

        def check_installed
          if !schema_class.respond_to?(:operation_store) || schema_class.operation_store.nil?
            render "graphql/dashboard/operation_store/not_installed"
          end
        end

        def init_client(name: nil, secret: nil)
          GraphQL::Pro::OperationStore::ClientRecord.new(
            name: name,
            secret: secret,
            created_at: nil,
            operations_count: 0,
            archived_operations_count: 0,
            last_synced_at: nil,
            last_used_at: nil,
          )
        end
      end

      class OperationsController < Dashboard::ApplicationController
      end

      class IndexEntriesController < Dashboard::ApplicationController
      end
    end
  end
end
