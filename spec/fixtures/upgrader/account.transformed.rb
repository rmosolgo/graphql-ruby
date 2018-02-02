# frozen_string_literal: true

module Platform
  module Unions
    class Account < Platform::Unions::Base
      description "Users and organizations."
      visibility :internal

      possible_types(
        Objects::User,
        Objects::Organization,
        Objects::Bot,
      )

      def self.resolve_type(obj, ctx)
        :stand_in
      end
    end
  end
end
