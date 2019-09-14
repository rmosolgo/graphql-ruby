# frozen_string_literal: true
require "graphql/dataloader/loader"
require "graphql/dataloader/query_instrumentation"

module GraphQL
  class Dataloader
    def self.use(schema, dataloader_context_key: :dataloader)
      instrumenter = Dataloader::QueryInstrumentation.new(
        dataloader_class: self,
        dataloader_context_key: dataloader_context_key,
      )
      schema.instrument(:query, instrumenter)
    end

    attr_reader :loaders

    def initialize(query)
      @query = query

      @loaders = Hash.new do |h, loader_cls|
        h[loader_cls] = Hash.new do |h2, loader_key|
          h2[loader_key] = loader_cls.new(@query.context, loader_key)
        end
      end
    end
  end
end
