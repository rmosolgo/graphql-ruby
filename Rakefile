# frozen_string_literal: true
require "bundler/gem_helper"
Bundler::GemHelper.install_tasks

require "rake/testtask"
require_relative "lib/graphql/rake_task/validate"
require 'rake/extensiontask'

TEST_LIBS = ["spec", "lib", "graphql-c_parser/lib"]

def graphql_test_files
  exclude_integrations = []
  ['mongoid', 'rails'].each do |integration|
    begin
      require integration
    rescue LoadError
      exclude_integrations << integration
    end
  end

  exclude_docs = begin
    require "rdoc"
    require "rdoc/generator/aliki"
    false
  rescue LoadError
    true
  end

  FileList.new("spec/**/*_spec.rb") do |fl|
    fl.exclude(*exclude_integrations.map { |int| "spec/integration/#{int}/**/*" })
    fl.exclude("spec/docs/**/*") if exclude_docs
  end
end

# After 2.7, there were not warnings for uninitialized ivars anymore
TEST_WARNINGS = RUBY_VERSION >= "3"

Rake::TestTask.new("test:serial") do |t|
  t.description = "Run the test suite in a single process"
  t.libs.concat(TEST_LIBS)
  t.test_files = graphql_test_files
  t.warning = TEST_WARNINGS
end

desc "Run the test suite (in parallel, unless TEST=..., SERIAL=1, or CI is set)"
task :test do
  if ENV["TEST"] || ENV["SERIAL"] || ENV["CI"]
    Rake::Task["test:serial"].invoke
  else
    Rake::Task["test:parallel"].invoke
  end
end

namespace :test do
  desc "Run the test suite with parallel_tests (PARALLEL_TEST_PROCESSORS=n to pick the number of workers)"
  task :parallel do
    require "parallel_tests"

    # Don't merge coverage from a previous run into this one
    FileUtils.rm_f("coverage/.resultset.json")
    ENV["PARALLEL_TESTS_EXECUTABLE"] = ["ruby", ("-w" if TEST_WARNINGS), *TEST_LIBS.map { |l| "-I#{l}" }].compact.join(" ")

    # spec_helper.rb records runtimes in tmp/parallel_runtime_test.log. When it covers enough files,
    # parallel_tests uses it to group files by runtime; otherwise it groups them by file size.
    ParallelTests::CLI.new.run(["--type", "test", "--serialize-stdout", "--combine-stderr", *graphql_test_files])
  end
end

# gemfiles/docs.gemfile only installs what the documentation build needs
unless Bundler.default_gemfile.basename.to_s == "docs.gemfile"
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
end

default_tasks = [:test, :rubocop]
if ENV["SYSTEM_TESTS"]
  task(default: ["test:system"] + default_tasks)
else
  task(default: default_tasks)
end

def assert_dependency_version(dep_name, required_version, check_script)
  version = `#{check_script}`
  if !version.include?(required_version)
    raise <<-ERR
build_parser requires #{dep_name} version "#{required_version}", but found:

  $ #{check_script}
  > #{version}

To fix this issue:

- Update #{dep_name} to the required version
- Update the assertion in `Rakefile` to match the current version
ERR
  end
end

namespace :bench do
  def prepare_benchmark
    $LOAD_PATH << "./lib" << "./spec/support"
    require_relative("./benchmark/run.rb")
  end

  desc "Benchmark parsing"
  task :parse do
    prepare_benchmark
    GraphQLBenchmark.run("parse")
  end

  desc "Benchmark lexical analysis"
  task :scan do
    prepare_benchmark
    GraphQLBenchmark.run("scan")
  end

  desc "Benchmark the introspection query"
  task :query do
    prepare_benchmark
    GraphQLBenchmark.run("query")
  end

  desc "Run the benchmarks tracked over time, measuring iterations per second"
  task :track_runtime do
    prepare_benchmark
    require_relative("./benchmark/track.rb")
    GraphQLBenchmark::Track.runtime
  end

  desc "Run the benchmarks tracked over time, measuring memory allocations"
  task :track_memory do
    prepare_benchmark
    require_relative("./benchmark/track.rb")
    GraphQLBenchmark::Track.memory
  end

  desc "Benchmark validation of several queries"
  task :validate do
    prepare_benchmark
    GraphQLBenchmark.run("validate")
  end

  desc "Profile a validation"
  task :validate_memory do
    prepare_benchmark
    GraphQLBenchmark.validate_memory
  end

  desc "Generate a profile of the introspection query"
  task :profile do
    prepare_benchmark
    GraphQLBenchmark.profile
  end

  desc "Run benchmarks on a very large result"
  task :profile_large_result do
    prepare_benchmark
    GraphQLBenchmark.profile_large_result
  end

  desc "Run benchmarks on a small result"
  task :profile_small_result do
    prepare_benchmark
    GraphQLBenchmark.profile_small_result
  end

  desc "Run introspection on a small schema"
  task :profile_small_introspection do
    prepare_benchmark
    GraphQLBenchmark.profile_small_introspection
  end

  desc "Dump schema to SDL"
  task :profile_to_definition do
    prepare_benchmark
    GraphQLBenchmark.profile_to_definition
  end

  desc "Load schema from SDL"
  task :profile_from_definition do
    prepare_benchmark
    GraphQLBenchmark.profile_from_definition
  end

  desc "Compare GraphQL-Batch and GraphQL-Dataloader"
  task :profile_batch_loaders do
    prepare_benchmark
    GraphQLBenchmark.profile_batch_loaders
  end

  desc "Run benchmarks on schema creation"
  task :profile_boot do
    prepare_benchmark
    GraphQLBenchmark.profile_boot
  end

  desc "Check the memory footprint of a large schema"
  task :profile_schema_memory_footprint do
    prepare_benchmark
    GraphQLBenchmark.profile_schema_memory_footprint
  end

  desc "Check the depth of the stacktrace during execution"
  task :profile_stack_depth do
    prepare_benchmark
    GraphQLBenchmark.profile_stack_depth
  end

  desc "Run a very big introspection query"
  task :profile_large_introspection do
    prepare_benchmark
    GraphQLBenchmark.profile_large_introspection
  end

  task :profile_small_query_on_large_schema do
    prepare_benchmark
    GraphQLBenchmark.profile_small_query_on_large_schema
  end

  desc "Run analysis on a big query"
  task :profile_large_analysis do
    prepare_benchmark
    GraphQLBenchmark.profile_large_analysis
  end

  desc "Run analysis on parsing"
  task :profile_parse do
    prepare_benchmark
    GraphQLBenchmark.profile_parse
  end
end

namespace :test do
  desc "Run system tests for ActionCable subscriptions"
  task :system do
    success = Dir.chdir("spec/dummy") do
      system("bundle install")
      system("bundle exec bin/rails test:system")
    end
    success || abort
  end

  task js: "js:test"
end

namespace :js do
  client_dir = "./javascript_client"

  desc "Run the tests for javascript_client"
  task :test do
    success = Dir.chdir(client_dir) do
      system("yarn run test")
    end
    success || abort
  end

  desc "Install JS dependencies"
  task :install do
    Dir.chdir(client_dir) do
      system("yarn install")
    end
  end

  desc "Compile TypeScript to JavaScript"
  task :build do
    Dir.chdir(client_dir) do
      system("yarn tsc")
    end
  end
  task all: [:install, :build, :test]
end

task :build_c_lexer do
  assert_dependency_version("Ragel", "7.0.4", "ragel -v")
  `ragel -F1 graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl`
end

Rake::ExtensionTask.new("graphql_c_parser_ext") do |t|
  t.ext_dir = 'graphql-c_parser/ext/graphql_c_parser_ext'
  t.lib_dir = "graphql-c_parser/lib/graphql"
end

task :build_yacc_parser do
  assert_dependency_version("Bison", "3.8", "yacc --version")
  `yacc graphql-c_parser/ext/graphql_c_parser_ext/parser.y -o graphql-c_parser/ext/graphql_c_parser_ext/parser.c -Wyacc`
end

task :move_binary do
  # For some reason my local env doesn't respect the `lib_dir` configured above
  `mv graphql-c_parser/lib/*.bundle graphql-c_parser/lib/graphql`
end

namespace :docs do
  desc "Build the RDoc/Aliki documentation site"
  task build: "docs:rdoc:build"

  desc "Build and run documentation quality checks"
  task check: "docs:rdoc:build" do
    ruby "tool/docs/check.rb"
    ruby "tool/docs/type_signatures.rb", "--check"
    ruby "tool/docs/compatibility.rb", "--root", "tmp/rdoc-site", "--rdoc", "tmp/rdoc-site/js/search_data.js", "--strict", "--json", "tmp/rdoc-api-compatibility.json"
    ruby "tool/docs/link_checker.rb", "--root", "tmp/rdoc-site", "--strict", "--json", "tmp/rdoc-link-report.json"
    ruby "tool/docs/rdoc_ref_checker.rb", "--root", "tmp/rdoc-site", "--json", "tmp/rdoc-ref-report.json"
    sh "node tool/docs/assets/graphql_highlighter_test.js"
  end

  desc "Build the documentation twice and compare generated files"
  # Reuses the `docs:rdoc:build` output as the first build, so running
  # `rake docs:check docs:build_twice` builds the site only twice in total.
  task build_twice: "docs:rdoc:build" do
    require_relative "tool/docs/build"
    require "digest"
    require "fileutils"
    require "pathname"
    first = "tmp/rdoc-site"
    second = GraphQLDocs::Build.new.build_site(output: "tmp/rdoc-site-second")
    digest = lambda do |root|
      Dir[File.join(root, "**", "*")].select { |path| File.file?(path) }.sort.to_h do |path|
        [Pathname.new(path).relative_path_from(Pathname.new(root)).to_s, Digest::SHA256.file(path).hexdigest]
      end
    end
    raise "RDoc output is not reproducible" unless digest.call(first) == digest.call(second)
    puts "RDoc output is reproducible"
  ensure
    FileUtils.rm_rf("tmp/rdoc-site-second")
  end

  namespace :rdoc do
    desc "Build the shadow RDoc/Aliki documentation site"
    task :build do
      require_relative "tool/docs/build"
      GraphQLDocs::Build.new.build_site
    end

    desc "Build versioned RDoc/Aliki API documentation"
    task :build_version, [:version] do |_task, args|
      require_relative "tool/docs/build"
      version = args[:version] || ENV["GRAPHQL_VERSION"] || raise(ArgumentError, "A version is required")
      GraphQLDocs::Build.new.build_version(version)
    end

    desc "Build the shadow RDoc site and serve it locally"
    task :serve => :build do
      require "webrick"
      server = WEBrick::HTTPServer.new(
        Port: Integer(ENV.fetch("PORT", "8808")),
        DocumentRoot: File.expand_path("tmp/rdoc-site"),
      )
      trap("INT") { server.shutdown }
      puts "Serving RDoc documentation at http://127.0.0.1:#{server.config[:Port]}"
      server.start
    end
  end
end

desc "Build the C Extension"
task build_ext: [:build_c_lexer, :build_yacc_parser, "compile:graphql_c_parser_ext", :move_binary]
