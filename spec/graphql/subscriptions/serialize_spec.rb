# frozen_string_literal: true
require "spec_helper"

if defined?(GlobalID)
  GlobalID.app = "graphql-ruby-test"

  class GlobalIDUser
    include GlobalID::Identification

    attr_reader :id

    def initialize(id)
      @id = id
    end

    def self.find(id)
      GlobalIDUser.new(id)
    end

    def ==(that)
      self.id == that.id
    end
  end
end

describe GraphQL::Subscriptions::Serialize do
  if defined?(GlobalID)
    it "should serialize GlobalID::Identification in Array/Hash" do
      user_a = GlobalIDUser.new("a")
      user_b = GlobalIDUser.new("b")

      str_a = GraphQL::Subscriptions::Serialize.dump(["first", 2, user_a])
      str_b = GraphQL::Subscriptions::Serialize.dump({first: 'first', second: 2, user: user_b})

      assert_equal str_a, '["first",2,{"__gid__":"Z2lkOi8vZ3JhcGhxbC1ydWJ5LXRlc3QvR2xvYmFsSURVc2VyL2E"}]'
      assert_equal str_b, '{"first":"first","second":2,"user":{"__gid__":"Z2lkOi8vZ3JhcGhxbC1ydWJ5LXRlc3QvR2xvYmFsSURVc2VyL2I"}}'
    end

    it "should deserialize GlobalID::Identification in Array/Hash" do
      user_a = GlobalIDUser.new("a")
      user_b = GlobalIDUser.new("b")

      str_a = '["first",2,{"__gid__":"Z2lkOi8vZ3JhcGhxbC1ydWJ5LXRlc3QvR2xvYmFsSURVc2VyL2E"}]'
      str_b = '{"first":"first","second":2,"user":{"__gid__":"Z2lkOi8vZ3JhcGhxbC1ydWJ5LXRlc3QvR2xvYmFsSURVc2VyL2I"}}'

      parsed_obj_a = GraphQL::Subscriptions::Serialize.load(str_a)
      parsed_obj_b = GraphQL::Subscriptions::Serialize.load(str_b)

      assert_equal parsed_obj_a, ["first", 2, user_a]
      assert_equal parsed_obj_b, {'first' => 'first', 'second' => 2, 'user' => user_b}
    end
  end
end
