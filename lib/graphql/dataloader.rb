# frozen_string_literal: true
require "graphql/dataloader/loader"

module GraphQL
  class Dataloader
    def self.use(schema, default_loaders: true, threaded: true, loaders: {})
      dataloader_class = self.class_for(loaders: loaders, default_loaders: default_loaders, threaded: threaded)
      schema.const_set(:Dataloader, dataloader_class)
      instrumenter = Dataloader::Instrumentation.new(
        dataloader_class: dataloader_class,
      )
      schema.instrument(:multiplex, instrumenter)
      schema.lazy_resolve(Dataloader::Loader::PendingLoad, :sync)
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
        multiplex.context[:dataloader] = dl
        multiplex.queries.each do |q|
          q.context[:dataloader] = dl
        end
      end

      def after_multiplex(_m)
      end
    end

    class << self
      def class_for(loaders:, threaded:, default_loaders:)
        Class.new(self) do
          self.threaded = threaded
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

      attr_writer :threaded

      def threaded?
        @threaded
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
