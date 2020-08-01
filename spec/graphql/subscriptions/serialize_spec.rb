# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Subscriptions::Serialize do
  def serialize_dump(v)
    GraphQL::Subscriptions::Serialize.dump(v)
  end

  def serialize_load(v)
    GraphQL::Subscriptions::Serialize.load(v)
  end

  if defined?(GlobalID)
    it "should serialize GlobalID::Identification in Array/Hash" do
      user_a = GlobalIDUser.new("a")
      user_b = GlobalIDUser.new("b")

      str_a = serialize_dump(["first", 2, user_a])
      str_b = serialize_dump({"first" => 'first', "second" => 2, "user" => user_b})

      assert_equal str_a, '["first",2,{"__gid__":"Z2lkOi8vZ3JhcGhxbC1ydWJ5LXRlc3QvR2xvYmFsSURVc2VyL2E"}]'
      assert_equal str_b, '{"first":"first","second":2,"user":{"__gid__":"Z2lkOi8vZ3JhcGhxbC1ydWJ5LXRlc3QvR2xvYmFsSURVc2VyL2I"}}'
    end

    it "should deserialize GlobalID::Identification in Array/Hash" do
      user_a = GlobalIDUser.new("a")
      user_b = GlobalIDUser.new("b")

      str_a = '["first",2,{"__gid__":"Z2lkOi8vZ3JhcGhxbC1ydWJ5LXRlc3QvR2xvYmFsSURVc2VyL2E"}]'
      str_b = '{"first":"first","second":2,"user":{"__gid__":"Z2lkOi8vZ3JhcGhxbC1ydWJ5LXRlc3QvR2xvYmFsSURVc2VyL2I"}}'

      parsed_obj_a = serialize_load(str_a)
      parsed_obj_b = serialize_load(str_b)

      assert_equal parsed_obj_a, ["first", 2, user_a]
      assert_equal parsed_obj_b, {'first' => 'first', 'second' => 2, 'user' => user_b}
    end
  end

  it "can deserialize symbols" do
    value = { a: :a, "b" => 2 }

    dumped = serialize_dump(value)
    expected_dumped = '{"a":{"__sym__":"a"},"b":2,"__sym_keys__":["a"]}'
    assert_equal expected_dumped, dumped
    loaded = serialize_load(dumped)
    assert_equal value, loaded
  end

  it "can deserialize date/times" do
    datetime = DateTime.parse("2020-01-03 10:11:12")
    time = Time.new
    date = Date.today
    [datetime, time, date].each do |timestamp|
      serialized = serialize_dump(timestamp)
      reloaded = serialize_load(serialized)
      assert_equal timestamp, reloaded, "#{timestamp.inspect} is serialized to #{serialized.inspect} and reloaded"
    end
  end

  it "can deserialize openstructs" do
    os = OpenStruct.new(a: 1.2, b: :c, d: Time.new, e: OpenStruct.new(f: [1, 2, 3]))
    serialized = serialize_dump(os)
    reloaded = serialize_load(serialized)
    assert_equal os, reloaded, "It reloads #{os.inspect} from #{serialized.inspect}"
  end
end
