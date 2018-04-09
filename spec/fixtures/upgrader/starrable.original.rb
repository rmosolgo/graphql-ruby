# frozen_string_literal: true

module Platform
  module Interfaces
    Starrable = GraphQL::InterfaceType.define do
      name "Starrable"
      description "Things that can be starred."

      global_id_field :id

      field :viewerHasStarred, !types.Boolean do
        argument :preceedsConnectionMethod, types.Boolean
        description "Returns a boolean indicating whether the viewing user has starred this starrable."

        resolve ->(object, arguments, context) do
          if context[:viewer]
            ->(test_inner_proc) do
              context[:viewer].starred?(object)
            end
          else
            false
          end
        end
      end

      connection :stargazers, -> { !Connections::Stargazer } do
        description "A list of users who have starred this starrable."

        argument :orderBy, Inputs::StarOrder, "Order for connection"

        resolve ->(object, arguments, context) do
          scope = case object
          when Repository
            object.stars
          when Gist
            GistStar.where(gist_id: object.id)
          end

          table = scope.table_name
          if order_by = arguments["orderBy"]
            scope = scope.order("#{table}.#{order_by["field"]} #{order_by["direction"]}")
          end

          scope
        end
      end
    end
  end
end
