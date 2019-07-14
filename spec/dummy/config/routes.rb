# frozen_string_literal: true

require 'graphql/endpoints/playground'

Rails.application.routes.draw do
  root to: "pages#show"

  mount GraphQL::Endpoints::Playground, at: '/graphql', playground: {
    endpoint: 'https://api.graph.cool/simple/v1/swapi'
  }
end
