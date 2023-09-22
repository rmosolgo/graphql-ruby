# frozen_string_literal: true

module GraphQL
  class Railtie < Rails::Railtie
    config.graphql = ActiveSupport::OrderedOptions.new
    config.graphql.parser_cache = false

    initializer("graphql.cache") do |app|
      if config.graphql.parser_cache
        Language::Parser.cache ||= Language::Cache.new(
          app.root.join("tmp/cache/graphql")
        )
      end
    end
  end
end
