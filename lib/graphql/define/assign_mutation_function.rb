# frozen_string_literal: true
module GraphQL
  module Define
    module AssignMutationFunction
      def self.call(target, function)
        # TODO: get all this logic somewhere easier to test

        if !function.type.is_a?(GraphQL::ObjectType)
          raise "Mutation functions must return object types (not #{function.type.unwrap})"
        end

        target.return_type = function.type.redefine {
          name(target.name + "Payload")
          field :clientMutationId, types.String, "A unique identifier for the client performing the mutation.", property: :client_mutation_id
        }

        target.arguments = function.arguments
        target.description = function.description
        target.resolve = ->(o, a, c) {
          res = function.call(o, a, c)
          ResultProxy.new(res, a[:clientMutationId])
        }
      end

      class ResultProxy < SimpleDelegator
        attr_reader :client_mutation_id
        def initialize(target, client_mutation_id)
          @client_mutation_id = client_mutation_id
          super(target)
        end
      end
    end
  end
end
