# frozen_string_literal: true
module GraphQL
  # There are two ways to apply the deprecated `!` DSL to class-style schema definitions:
  #
  # 1. Scoped by file (CRuby only), add to the top of the file:
  #
  #      using GraphQL::DeprecatedDSL
  #
  #   (This is a "refinement", there are also other ways to scope it.)
  #
  # 2. Global application, add before schema definition:
  #
  #      GraphQL::DeprecatedDSL.activate
  #
  module DeprecatedDSL
    def self.activate
      GraphQL::Schema::Member.extend(Methods)
    end
    module Methods
      def !
        to_non_null_type
      end
    end
    refine GraphQL::Schema::Member.singleton_class do
      include Methods
    end
  end
end
