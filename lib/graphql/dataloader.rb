# frozen_string_literal: true
require "graphql/dataloader/loader"
require "graphql/dataloader/instrumentation"

module GraphQL
  class Dataloader
    def self.use(schema)
      instrumenter = Dataloader::Instrumentation.new(
        dataloader_class: self,
      )
      schema.instrument(:multiplex, instrumenter)
    end

    attr_reader :loaders

    def initialize(multiplex)
      @multiplex = multiplex

      @loaders = Hash.new do |h, loader_cls|
        h[loader_cls] = Hash.new do |h2, loader_key|
          h2[loader_key] = loader_cls.new(@multiplex.context, loader_key)
        end
      end
    end
  end
end
