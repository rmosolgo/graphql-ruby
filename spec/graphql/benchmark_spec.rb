# frozen_string_literal: true
require "spec_helper"
require_relative "../../benchmark/run.rb"

if testing_coverage?
  describe "GraphQL execution benchmarks" do
    it "keeps memory benchmarks in source control" do
      validate_mem = GraphQLBenchmark.validate_memory(full_report: true)
      large_result = GraphQLBenchmark.memory_profile_large_result(full_report: true)

      dir = ci_running? ? "spec/ci" : "spec/artifacts"
      FileUtils.mkdir_p(dir)
      memory_report = <<-TXT
Validate Memory:
  - Allocated #{validate_mem.total_allocated} objects, #{validate_mem.total_allocated_memsize} bytes
  - Retained #{validate_mem.total_retained} objects, #{validate_mem.total_retained_memsize} bytes

Large Result Memory:
  - Allocated #{large_result.total_allocated} objects, #{large_result.total_allocated_memsize} bytes
  - Retained #{large_result.total_retained} objects, #{large_result.total_retained_memsize} bytes
TXT

      Dir.chdir(dir) do
        File.write("memory.txt", memory_report)
      end
    end
  end
end
