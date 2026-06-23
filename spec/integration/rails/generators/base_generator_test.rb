# frozen_string_literal: true

class BaseGeneratorTest < Rails::Generators::TestCase
  destination File.expand_path("../../tmp", File.dirname(__FILE__))
  setup :prepare_destination

  setup do
    Rails.application = OpenStruct.new(
      # Defaults from https://github.com/rails/rails/blob/main/railties/lib/rails/generators/rails/app/templates/config/initializers/filter_parameter_logging.rb.tt
      config: OpenStruct.new(
        filter_parameters: [
          :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn
        ]
      )
    )
  end

end
