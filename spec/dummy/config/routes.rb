# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "pages#show"

  mount GraphQL::IDE::Engine, at: '/graphql', editor: 'graphiql', csrf: true, options: {
    endpoint: '/graphql'
  }
end
