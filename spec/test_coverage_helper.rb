# frozen_string_literal: true
puts "Starting Code Coverage"
require 'simplecov'
SimpleCov.at_exit do
  text_result = +""
  SimpleCov.result.groups.each do |name, files|
    text_result << "Group: #{name}\n"
    text_result << "=" * 40
    text_result << "\n"
    files.each do |file|
      # Remove any local paths
      local_filename = file.filename.sub(/^.*graphql-ruby\/lib/, "graphql-ruby/lib")
      text_result << "#{local_filename} (coverage: #{file.covered_percent.round(2)}% / branch: #{file.branches_coverage_percent.round(2)}%)\n"
    end
    text_result << "\n"
  end
  # Write this file to track coverage in source control
  cov_file = "spec/artifacts/coverage.txt"
  # Raise in CI if this file isn't up-to-date
  if ci_running?
    FileUtils.mkdir_p("spec/ci")
    File.write("spec/ci/coverage.txt", text_result)
    ci_artifact_paths = Dir.glob("spec/ci/*.txt")
    any_artifact_changes = ci_artifact_paths.any? do |ci_artifact_path|
      committed_artifact_path = ci_artifact_path.sub("/ci/", "/artifacts/")
      File.read(ci_artifact_path) != File.read(committed_artifact_path)
    end
    if any_artifact_changes
      if `git config --global user.name` == ""
        `git config --global user.name "GraphQL-Ruby CI"`
        `git config --global user.email "<>"`
      end
      current_branch = ENV["GITHUB_HEAD_REF"].sub("refs/heads/", "")
      `git fetch origin #{current_branch}`
      `git checkout #{current_branch}`
      current_sha = `git rev-parse HEAD`.chomp
      new_branch = "update-artifacts-on-#{current_branch}-#{current_sha[0, 10]}"
      `git checkout -b #{new_branch}`
      ci_artifact_paths.each do |ci_artifact_path|
        FileUtils.cp(ci_artifact_path, ci_artifact_path.sub("/ci/", "/artifacts/"))
      end
      `git add spec`
      `git commit -m "Update artifacts (automatic)"`
      `git push origin #{new_branch}`
      comment = "
Some [development artifacts](https://graphql-ruby.org/development#artifacts) have changed.
Merge [this PR](https://github.com/rmosolgo/graphql-ruby/compare/#{current_branch}...#{new_branch}?expand=1) into your branch or update them locally with

```
COVERAGE=1 BUNDLE_GEMFILE=gemfiles/rails_6.1.gemfile bundle exec rake test
```

and commit the changes.
"
      `curl -X POST #{ENV["GITHUB_COMMENTS_URL"]} -H "Content-Type: application/json" -H "Authorization: token #{ENV["GITHUB_TOKEN"]}" --data '{ "body": "#{comment}" }'`
    end
  else
    FileUtils.mkdir_p("spec/artifacts")
    File.write(cov_file, text_result)
  end
  SimpleCov.result.format!
end

SimpleCov.start do
  enable_coverage :branch
  primary_coverage :branch
  add_filter %r{^/spec/}
  add_filter %r{^/benchmark/}
  add_group "Schema Definition", [
    "lib/graphql/schema",
    "lib/graphql/types",
    "lib/graphql/type_kinds.rb",
    "lib/graphql/rake_task",
    "lib/graphql/rubocop",
    "lib/graphql/invalid_name_error.rb",
    "lib/graphql/name_validator.rb",
  ]
  add_group "Language", [
    "lib/graphql/language",
    "lib/graphql/parse_error.rb",
    "lib/graphql/railtie.rb",
  ]
  add_group "Dataloader", ["lib/graphql/dataloader"]
  add_group "Pagination", ["lib/graphql/pagination"]
  add_group "Introspection", ["lib/graphql/introspection"]
  add_group "Execution", [
    "lib/graphql/static_validation",
    "lib/graphql/analysis",
    "lib/graphql/analysis_error.rb",
    "lib/graphql/backtrace",
    "lib/graphql/errors",
    "lib/graphql/execution",
    "lib/graphql/query",
    "lib/graphql/relay",
    "lib/graphql/tracing",
    "lib/graphql/runtime_type_error.rb",
    "lib/graphql/load_application_object_failed_error.rb",
    "lib/graphql/filter.rb",
    "lib/graphql/dig.rb",
    "lib/graphql/unauthorized_error.rb",
    "lib/graphql/unauthorized_field_error.rb",
    "lib/graphql/invalid_null_error.rb",
    "lib/graphql/coercion_error.rb",
    "lib/graphql/integer_encoding_error.rb",
    "lib/graphql/integer_decoding_error.rb",
    "lib/graphql/string_encoding_error.rb",
    "lib/graphql/runtime_type_error.rb",
    "lib/graphql/unresolved_type_error.rb",
  ]
  add_group "Subscriptions", ["lib/graphql/subscriptions"]
  add_group "Generators", "lib/generators"

  formatter SimpleCov::Formatter::HTMLFormatter
end
