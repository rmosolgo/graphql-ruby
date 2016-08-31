require "spec_helper"
require 'graphql/testing/parser_tests'

describe GraphQL::Language::Parser do
  include GraphQL::Testing::ParserTests
  subject { GraphQL::Language::Parser }
end
