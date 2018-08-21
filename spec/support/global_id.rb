# frozen_string_literal: true

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
