# frozen_string_literal: true
module Graphql
  class Dashboard < Rails::Engine
    module OperationStore
      module CheckInstalled
        def self.included(child_module)
          child_module.before_action(:check_installed)
        end

        def check_installed
          if !schema_class.respond_to?(:operation_store) || schema_class.operation_store.nil?
            render "graphql/dashboard/operation_store/not_installed"
          end
        end
      end
      class ClientsController < Dashboard::ApplicationController
        include CheckInstalled

        def index
          @order_by = params[:order_by] || "name"
          @order_dir = params[:order_dir].presence || "asc"
          clients_page = schema_class.operation_store.all_clients(
            page: params[:page]&.to_i || 1,
            per_page: params[:per_page]&.to_i || 25,
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
        include CheckInstalled

        def index
          @client_operations = client_name = params[:client_name]
          per_page = params[:per_page]&.to_i || 25
          page = params[:page]&.to_i || 1
          is_archived = params[:status] == :archived
          @operations_page = if @client_operations
            schema_class.operation_store.get_client_operations_by_client(
              client_name,
              page: page,
              per_page: per_page,
              is_archived: is_archived,
              order_by: "name",
              order_dir: "asc",
            )
          else
            schema_class.operation_store.all_operations(
              page: page,
              per_page: per_page,
              is_archived: is_archived,
              order_by: "name",
              order_dir: "asc",
            )
          end
        end

        def show
          digest = params[:digest]
          @operation = schema_class.operation_store.get_operation_by_digest(digest)
          if @operation
            # Parse & re-format the query
            document = GraphQL.parse(@operation.body)
            @graphql_source = document.to_query_string

            @client_operations = schema_class.operation_store.get_client_operations_by_digest(digest)
            @entries = schema_class.operation_store.get_index_entries_by_digest(digest)
          end
        end
      end

      class IndexEntriesController < Dashboard::ApplicationController
      end
    end
  end
end
