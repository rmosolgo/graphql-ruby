require "spec_helper"
require 'graphql/language/parser_tests'

describe GraphQL::Language::Parser do
  include GraphQL::Language::ParserTests
  subject { GraphQL::Language::Parser }
end
