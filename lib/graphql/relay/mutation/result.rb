# frozen_string_literal: true
module GraphQL
  module Relay
    class Mutation
      # Use this when the mutation's return type was generated from `return_field`s.
      # It delegates field lookups to the hash returned from `resolve`.
      # @api private
      class Result
        attr_reader :client_mutation_id
        def initialize(client_mutation_id:, result:)
          @client_mutation_id = client_mutation_id
          result && result.each do |key, value|
            self.public_send("#{key}=", value)
          end
        end

        class << self
          attr_accessor :mutation
        end

        # Build a subclass whose instances have a method
        # for each of `mutation_defn`'s `return_field`s
        # @param mutation_defn [GraphQL::Relay::Mutation]
        # @return [Class]
        def self.define_subclass(mutation_defn)
          subclass = Class.new(self) do
            mutation_result_methods = mutation_defn.return_type.all_fields.map do |f|
              f.property || f.name
            end
            attr_accessor(*mutation_result_methods)
            self.mutation = mutation_defn
          end
          subclass
        end
      end
    end
  end
end
