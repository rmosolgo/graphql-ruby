# frozen_string_literal: true
module Platform
  module Mutations
    Echo = GraphQL::Relay::Mutation.define do
      name 'EchoMutation'

      input_field :message, types.String

      field :data, types.String

      resolve ->(_obj, inputs, _ctx) {
        { data: inputs[:message] }
      }
    end

    Repeat = GraphQL::Relay::Mutation.define do
      name 'RepeatMutation'

      input_field :message, types.String

      field :data, types.String

      resolve ->(_obj, inputs, _ctx) {
        { data: inputs[:message] }
      }
    end
  end
end
