# frozen_string_literal: true
require "spec_helper"

describe "Next Execution resolver class authorization" do
  class NextResolverAuthorizationSchema < GraphQL::Schema
    RESOLVED = []

    class DeleteAll < GraphQL::Schema::Mutation
      field :ok, String, hash_key: :ok

      def self.authorized?(obj, ctx)
        super && ctx[:admin] == true
      end

      def resolve
        RESOLVED << :delete_all
        { ok: "deleted" }
      end
    end

    class GetSecret < GraphQL::Schema::Resolver
      type String, null: true

      def self.authorized?(obj, ctx)
        super && ctx[:admin] == true
      end

      def resolve
        RESOLVED << :secret
        "secret"
      end
    end

    class Query < GraphQL::Schema::Object
      field :secret, resolver: GetSecret
    end

    class Mutation < GraphQL::Schema::Object
      field :delete_all, mutation: DeleteAll
    end

    query(Query)
    mutation(Mutation)
    use GraphQL::Execution::Next
  end

  before { NextResolverAuthorizationSchema::RESOLVED.clear }

  it "reports authorizes? for resolvers that only override the class method" do
    assert NextResolverAuthorizationSchema::GetSecret.authorizes?({})
    assert NextResolverAuthorizationSchema::DeleteAll.authorizes?({})
    refute Class.new(GraphQL::Schema::Resolver).authorizes?({})
  end

  [:execute, :execute_next].each do |method_name|
    describe "with #{method_name}" do
      it "doesn't run an unauthorized mutation" do
        result = NextResolverAuthorizationSchema.public_send(method_name, "mutation { deleteAll { ok } }", context: { admin: false }).to_h
        assert_nil result["data"]["deleteAll"]
        assert_equal [], NextResolverAuthorizationSchema::RESOLVED
      end

      it "doesn't resolve an unauthorized resolver field" do
        result = NextResolverAuthorizationSchema.public_send(method_name, "{ secret }", context: { admin: false }).to_h
        assert_nil result["data"]["secret"]
        assert_equal [], NextResolverAuthorizationSchema::RESOLVED
      end

      it "runs authorized resolvers" do
        result = NextResolverAuthorizationSchema.public_send(method_name, "mutation { deleteAll { ok } }", context: { admin: true }).to_h
        assert_equal "deleted", result["data"]["deleteAll"]["ok"]
        result = NextResolverAuthorizationSchema.public_send(method_name, "{ secret }", context: { admin: true }).to_h
        assert_equal "secret", result["data"]["secret"]
      end
    end
  end
end
