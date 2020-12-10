# frozen_string_literal: true
require "erb"

module GitHubActionsUnitTests
  def self.generate
    template = File.read("spec/support/unit_tests.yaml.erb")
    gemfiles = Dir.glob("gemfiles/**.gemfile").sort
    erb = ERB.new(template, trim_mode: "-")
    erb.result_with_hash({ gemfiles: gemfiles })
  end

  def self.update!
    text = self.generate
    File.write(".github/workflows/unit_tests.yaml", text)
  end
end
