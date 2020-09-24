# frozen_string_literal: true
require "graphql/dataloader/loader"
require "graphql/dataloader/promise"

module GraphQL
  class Dataloader
    class LoadError < GraphQL::Error
      attr_accessor :graphql_path

      attr_writer :message

      def message
        @message || super
      end
    end

    def self.use(schema, default_loaders: true, loaders: {})
      dataloader_class = self.class_for(loaders: loaders, default_loaders: default_loaders)
      schema.const_set(:Dataloader, dataloader_class)
      instrumenter = Dataloader::Instrumentation.new(
        dataloader_class: dataloader_class,
      )
      schema.instrument(:multiplex, instrumenter)
      schema.lazy_resolve(Dataloader::Promise, :sync)
      # TODO this won't work if the mutation is hooked up after this
      schema.mutation.fields.each do |name, field|
        field.extension(MutationFieldExtension)
      end
    end

    class MutationFieldExtension < GraphQL::Schema::FieldExtension
      def resolve(object:, arguments:, context:, **_rest)
        context[:dataloader].clear
        begin
          return_value = yield(object, arguments)
          GraphQL::Execution::Lazy.sync(return_value)
        ensure
          context[:dataloader].clear
        end
      end
    end

    class Instrumentation
      def initialize(dataloader_class:)
        @dataloader_class = dataloader_class
      end

      def before_multiplex(multiplex)
        dl = @dataloader_class.new(multiplex)
        Dataloader.current = dl
        multiplex.context[:dataloader] = dl
        multiplex.queries.each do |q|
          q.context[:dataloader] = dl
        end
      end

      def after_multiplex(_m)
        Dataloader.current = nil
      end
    end

    class << self
      def class_for(loaders:, default_loaders:)
        Class.new(self) do
          if default_loaders
            # loader(GraphQL::Dataloader::HttpLoader)
            # loader(GraphQL::Dataloader::ActiveRecordLoader)
            # loader(GraphQL::Dataloader::RedisLoader)
          end
          loaders.each do |custom_loader|
            loader(custom_loader)
          end
        end
      end

      def loader_map
        @loader_map ||= {}
      end

      def loader(loader_class)
        loader_map[loader_class.dataloader_key] = loader_class
        # Add shortcut access
        define_method(loader_class.dataloader_key) do  |*key_parts|
          # Return a new instance of this class, initialized with these keys (or key)
          @loaders[loader_class][key_parts]
        end
      end

      def current
        Thread.current[:graphql_dataloader]
      end

      def current=(dataloader)
        Thread.current[:graphql_dataloader] = dataloader
      end
    end

    def initialize(multiplex)
      @multiplex = multiplex

      @loaders = Hash.new do |h, loader_cls|
        h[loader_cls] = Hash.new do |h2, loader_key|
          h2[loader_key] = loader_cls.new(@multiplex.context, *loader_key)
        end
      end
    end

    attr_reader :loaders

    def clear
      @loaders.clear
    end
  end
end
