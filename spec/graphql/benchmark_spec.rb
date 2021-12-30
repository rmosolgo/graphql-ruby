# frozen_string_literal: true
require "spec_helper"
require_relative "../../benchmark/run.rb"

if ENV["COVERAGE"]
  describe "GraphQL execution benchmarks" do
    it "keeps memory benchmarks in source control" do
      validate_mem, _err = capture_io do
        GraphQLBenchmark.validate_memory
      end

      large_result, _err = capture_io do
        GraphQLBenchmark.memory_profile_large_result
      end


      dir = ENV["GITHUB_ACTIONS"] ? "spec/ci" : "spec/artifacts"
      FileUtils.mkdir_p(dir)
      Dir.chdir(dir) do
        File.write("validate_memory.txt", validate_mem)
        File.write("large_result_memory.txt", large_result)
      end
    end
  end
end
