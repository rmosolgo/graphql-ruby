# frozen_string_literal: true

class BaseGeneratorTest < Rails::Generators::TestCase
  destination GENERATOR_TMP_DIR
  setup :prepare_destination
end
