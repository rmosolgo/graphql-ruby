# frozen_string_literal: true

module Platform
  module Interfaces
    module Starrable
      include Platform::Interfaces::Base
      description "Things that can be starred."

      global_id_field :id

      field :viewer_has_starred, Boolean, description: "Returns a boolean indicating whether the viewing user has starred this starrable.", null: false do
        argument :preceeds_connection_method, Boolean, required: false
      end

      def viewer_has_starred(**arguments)
        if context[:viewer]
          ->(test_inner_proc) do
            context[:viewer].starred?(object)
          end
        else
          false
        end
      end

      field :stargazers, Connections::Stargazer, description: "A list of users who have starred this starrable.", null: false, connection: true do
        argument :order_by, Inputs::StarOrder, "Order for connection", required: false
      end

      def stargazers(**arguments)
        scope = case object
        when Repository
          object.stars
        when Gist
          GistStar.where(gist_id: object.id)
        end

        table = scope.table_name
        if order_by = arguments[:order_by]
          scope = scope.order("#{table}.#{order_by["field"]} #{order_by["direction"]}")
        end

        scope
      end
    end
  end
end
