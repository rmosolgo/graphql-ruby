# frozen_string_literal: true

guard :minitest, test_file_patterns: ["*_spec.rb"] do
  # with Minitest::Spec
  watch(%r{^spec/(.*)_spec\.rb})
  watch(%r{^lib/(.+)\.rb})          { |m|
    # When a project file changes, run any of:
    # - Corresponding `spec/` file
    # - Corresponding `spec/` file
    #   for the file named in `test_via:`

    to_run = []
    matching_spec = "spec/#{m[1]}_spec.rb"
    if File.exist?(matching_spec)
      to_run << matching_spec
    end

    # If the file was deleted, it won't exist anymore
    if File.exist?(m[0])
      # Find a `# test_via:` macro to automatically run another test
      body = File.read(m[0])
      test_via_match = body.match(/test_via: (.*)/)
      if test_via_match
        test_via_path = test_via_match[1]
        companion_file = Pathname.new(m[0] + "/../" + test_via_path)
          .cleanpath
          .to_s
          .sub(/.rb/, "_spec.rb")
          .sub("lib/", "spec/")
          to_run << companion_file
      end
    end

    # 0+ files
    to_run
  }
  watch(%r{^spec/spec_helper\.rb})  { "spec" }
  watch(%r{^spec/support/.*\.rb})   { "spec" }
end

guard "rake", task: "build_parser" do
  watch("lib/graphql/language/parser.y")
  watch("lib/graphql/language/lexer.rl")
end

guard :rubocop, all_on_start: false do
  watch(%r{^spec/.*.\rb})
  watch(%r{^lib/.*\.rb})
end
