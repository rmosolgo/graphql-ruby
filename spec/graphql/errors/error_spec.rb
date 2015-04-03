require 'spec_helper'

describe GraphQL::Error do
  describe "#to_s" do
    it 'includes a link to documentation' do
      err = assert_raises(GraphQL::Error) { raise GraphQL::Error, "Something is messed up!" }
      assert_match(/rubydoc.*\/GraphQL\/Error/, err.to_s)
    end
  end
end