# typed: true

# DO NOT EDIT MANUALLY
# This file was pulled from a central RBI files repository.
# Please run `bin/tapioca annotations` to update it.

module GraphQL
  class << self
    # @version >= 2.3.1
    sig { params(graphql_string: String, trace: T.untyped, filename: T.untyped, max_tokens: T.untyped).returns(GraphQL::Language::Nodes::Document) }
    def parse(graphql_string, trace: T.unsafe(nil), filename: T.unsafe(nil), max_tokens: T.unsafe(nil)); end
  end
end

class GraphQL::Backtrace
  Elem = type_member { { fixed: T.untyped } }
end

class GraphQL::Schema
  class << self
    sig { params(query_str: String, kwargs: T.untyped).returns(GraphQL::Query::Result) }
    def execute(query_str = T.unsafe(nil), **kwargs); end
  end
end

class GraphQL::Schema::InputObject < ::GraphQL::Schema::Member
  sig { returns(GraphQL::Query::Context) }
  def context; end
end

class GraphQL::Schema::Object < ::GraphQL::Schema::Member
  sig { returns(GraphQL::Query::Context) }
  def context; end
end

class GraphQL::Schema::Resolver
  sig { returns(GraphQL::Query::Context) }
  def context; end
end

module GraphQL::Schema::Member::HasFields
  # @version >= 2.5.17
  sig { params(name_positional: T.untyped, type_positional: T.untyped, desc_positional: T.untyped, kwargs: T.untyped, block: T.nilable(T.proc.params(field: GraphQL::Schema::Field).bind(GraphQL::Schema::Field).void)).returns(T.untyped) }
  def field(name_positional = T.unsafe(nil), type_positional = T.unsafe(nil), desc_positional = T.unsafe(nil), **kwargs, &block); end
end

module GraphQL::Schema::Member::BaseDSLMethods
  sig { params(new_description: String).returns(T.nilable(String)) }
  def description(new_description = T.unsafe(nil)); end
end

module GraphQL::Schema::Interface
  mixes_in_class_methods ::GraphQL::Schema::Member::BaseDSLMethods
  mixes_in_class_methods ::GraphQL::Schema::Member::HasFields
end
