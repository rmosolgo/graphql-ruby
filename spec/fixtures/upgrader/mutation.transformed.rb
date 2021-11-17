# frozen_string_literal: true
module Platform
  module Mutations
    class Echo < Mutations::BaseMutation
      graphql_name 'EchoMutation'

      argument :message, String, required: false

      field :data, String

      def resolve(**inputs)
        { data: inputs[:message] }
      end
    end

    class Repeat < Mutations::BaseMutation
      graphql_name 'RepeatMutation'

      argument :message, String, required: false

      field :data, String

      def resolve(**inputs)
        { data: inputs[:message] }
      end
    end
  end
end
