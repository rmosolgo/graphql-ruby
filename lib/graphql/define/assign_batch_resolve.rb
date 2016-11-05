module GraphQL
  module Define
    module AssignBatchResolve
      def self.call(field_defn, loader, *loader_args, resolve_func)
        field_defn.batch_loader = GraphQL::Execution::Batch::BatchLoader.new(loader, loader_args)
        field_defn.resolve = resolve_func
      end
    end
  end
end
