# frozen_string_literal: true
module GraphQL
  # There are two ways to apply the deprecated `!` DSL to class-style schema definitions:
  #
  # 1. Scoped by file (CRuby only), add to the top of the file:
  #
  #      using GraphQL::DeprecationDSL
  #
  #   (This is a "refinement", there are also other ways to scope it.)
  #
  # 2. Global application, add before schema definition:
  #
  #      GraphQL::DeprecationDSL.activate
  #
  module DeprecatedDSL
    TYPE_CLASSES = [
      GraphQL::Schema::Scalar,
      GraphQL::Schema::Enum,
      GraphQL::Schema::InputObject,
      GraphQL::Schema::Union,
      GraphQL::Schema::Interface,
      GraphQL::Schema::Object,
    ]

    def self.activate
      deprecated_caller = caller(1, 1).first
      GraphQL::Deprecation.warn "DeprecatedDSL will be removed from GraphQL-Ruby 2.0, use `.to_non_null_type` instead of `!` and remove `.activate` from #{deprecated_caller}"
      TYPE_CLASSES.each { |c| c.extend(Methods) }
      GraphQL::Schema::List.include(Methods)
      GraphQL::Schema::NonNull.include(Methods)
    end

    module Methods
      def !
        deprecated_caller = caller(1, 1).first
        GraphQL::Deprecation.warn "DeprecatedDSL will be removed from GraphQL-Ruby 2.0, use `.to_non_null_type` instead of `!` at #{deprecated_caller}"
        to_non_null_type
      end
    end

    TYPE_CLASSES.each do |type_class|
      refine type_class.singleton_class do
        include Methods
      end
    end
  end
end
