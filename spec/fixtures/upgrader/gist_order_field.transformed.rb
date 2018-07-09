# frozen_string_literal: true

module Platform
  module Enums
    class GistOrderField < Platform::Enums::Base
      description "Properties by which gist connections can be ordered."

      value "CREATED_AT", "Order gists by creation time", value: "created_at"
      value "UPDATED_AT", "Order gists by update time", value: "updated_at"
      value "PUSHED_AT", "Order gists by push time", value: "pushed_at"
    end
  end
end
