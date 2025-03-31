# frozen_string_literal: true
require_relative "./installable"
module Graphql
  class Dashboard < Rails::Engine
    module OperationStore
      class BaseController < Dashboard::ApplicationController
        include Installable

        private

        def feature_installed?
          schema_class.respond_to?(:operation_store) && schema_class.operation_store.is_a?(GraphQL::Pro::OperationStore)
        end

        INSTALLABLE_COMPONENT_HEADER_HTML = "<code>OperationStore</code> isn't installed for this schema yet.".html_safe
        INSTALLABLE_COMPONENT_MESSAGE_HTML = <<-HTML.html_safe
          Learn more about improving performance and security with stored operations
          in the <a href="https://graphql-ruby.org/operation_store/overview.html"><code>OperationStore</code> docs</a>.
        HTML
      end

      class ClientsController < BaseController
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

      class OperationsController < BaseController
        def index
          @client_operations = client_name = params[:client_name]
          per_page = params[:per_page]&.to_i || 25
          page = params[:page]&.to_i || 1
          @is_archived = params[:archived_status] == :archived
          order_by = params[:order_by] || "name"
          order_dir = params[:order_dir]&.to_sym || :asc
          if @client_operations
            @operations_page = schema_class.operation_store.get_client_operations_by_client(
              client_name,
              page: page,
              per_page: per_page,
              is_archived: @is_archived,
              order_by: order_by,
              order_dir: order_dir,
            )
            opposite_archive_mode_count = schema_class.operation_store.get_client_operations_by_client(
              client_name,
              page: 1,
              per_page: 1,
              is_archived: !@is_archived,
              order_by: order_by,
              order_dir: order_dir,
            ).total_count
          else
            @operations_page = schema_class.operation_store.all_operations(
              page: page,
              per_page: per_page,
              is_archived: @is_archived,
              order_by: order_by,
              order_dir: order_dir,
            )
            opposite_archive_mode_count = schema_class.operation_store.all_operations(
              page: 1,
              per_page: 1,
              is_archived: !@is_archived,
              order_by: order_by,
              order_dir: order_dir,
            ).total_count
          end

          if @is_archived
            @archived_operations_count = @operations_page.total_count
            @unarchived_operations_count = opposite_archive_mode_count
          else
            @archived_operations_count = opposite_archive_mode_count
            @unarchived_operations_count = @operations_page.total_count
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

        def update
          is_archived = case params[:modification]
          when :archive
            true
          when :unarchive
            false
          else
            raise ArgumentError, "Unexpected modification: #{params[:modification].inspect}"
          end

          if (client_name = params[:client_name])
            operation_aliases = params[:operation_aliases]
            schema_class.operation_store.archive_client_operations(
              client_name: client_name,
              operation_aliases: operation_aliases,
              is_archived: is_archived
            )
            flash[:success] = "#{is_archived ? "Archived" : "Activated"} #{operation_aliases.size} #{"operation".pluralize(operation_aliases.size)}"
          else
            digests = params[:digests]
            schema_class.operation_store.archive_operations(
              digests: digests,
              is_archived: is_archived
            )
            flash[:success] = "#{is_archived ? "Archived" : "Activated"} #{digests.size} #{"operation".pluralize(digests.size)}"
          end
          head :no_content
        end
      end

      class IndexEntriesController < BaseController
        def index
          @search_term = if request.params["q"] && request.params["q"].length > 0
            request.params["q"]
          else
            nil
          end

          @index_entries_page = schema_class.operation_store.all_index_entries(
            search_term: @search_term,
            page: params[:page]&.to_i || 1,
            per_page: params[:per_page]&.to_i || 25,
          )
        end

        def show
          name = params[:name]
          @entry = schema_class.operation_store.index.get_entry(name)
          @chain = schema_class.operation_store.index.index_entry_chain(name)
          @operations = schema_class.operation_store.get_operations_by_index_entry(name)
        end
      end
    end
  end
end
