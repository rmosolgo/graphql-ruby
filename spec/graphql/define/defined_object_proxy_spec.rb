require "spec_helper"

class Target
  class Test
    attr_reader :target, :attribute, :value

    def call(target, attribute, value)
      @target = target
      @attribute = attribute
      @value = value
    end
  end

  def self.dictionary
    @dictionary ||= {
      test: Test.new,
    }
  end
end

describe GraphQL::Define::DefinedObjectProxy do
  let(:proxy){ GraphQL::Define::DefinedObjectProxy.new(Target.new) }

  it "converts a passed block to an argument if needed" do
    proxy.test "an attribute" do
      "some block"
    end

    target = Target.dictionary[:test]
    assert_equal target.attribute, "an attribute"
    assert_equal target.value.call, "some block"
  end
end
