require "spec_helper"

describe GraphQL do
  it "has an up-to-date unit_tests.yaml file" do
    expected_contents = GitHubActionsUnitTests.generate
    actual_contents = File.read(".github/workflows/unit_tests.yaml")
    # assert_equal expected_contents, actual_contents, "The unit_tests.yaml file is out-of-date. Run `be rake generate_unit_tests_workflow` and commit the changes."
  end
end
