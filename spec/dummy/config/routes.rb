# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "pages#show"

  mount GraphQL::IDE::Endpoint.new, at: '/rack_graphql', options: {
    endpoint: '/graphql'
  }

  mount GraphQL::IDE::Engine, at: '/rails_graphql', csrf: true, options: {
    endpoint: '/graphql'
  }
end
