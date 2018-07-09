# frozen_string_literal: true
module Platform
  module Objects
    Photo = GraphQL::ObjectType.define do
      field(:caption, types.String) do
        resolve(->(obj, _args, _ctx) { obj.caption })
      end
    end
  end
end
