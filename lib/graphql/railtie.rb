# frozen_string_literal: true

module GraphQL
  # Support {GraphQL::Parser::Cache}
  #
  # @example Enable the parser cache with default directory
  #
  #   config.graphql.parser_cache = true
  #
  class Railtie < Rails::Railtie
    config.graphql = ActiveSupport::OrderedOptions.new
    config.graphql.parser_cache = false
    config.before_eager_load do
      GraphQL.eager_load!
    end

    initializer("graphql.cache") do |app|
      if config.graphql.parser_cache
        Language::Parser.cache ||= Language::Cache.new(
          app.root.join("tmp/cache/graphql")
        )
      end
    end
  end
end
