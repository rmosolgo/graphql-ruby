# frozen_string_literal: true
require "spec_helper"
if RUBY_VERSION >= "3.1.1"
  require "async"
  describe GraphQL::Dataloader::AsyncDataloader do
    class AsyncSchema < GraphQL::Schema
      class SleepSource < GraphQL::Dataloader::Source
        def fetch(keys)
          max_sleep = keys.max
          # t1 = Time.now
          # puts "----- SleepSource => #{max_sleep} (from: #{keys})"
          sleep(max_sleep)
          # puts "----- SleepSource done #{max_sleep} after #{Time.now - t1}"
          keys.map { |_k| max_sleep }
        end
      end

      class WaitForSource < GraphQL::Dataloader::Source
        def initialize(tag)
          @tag = tag
        end

        def fetch(waits)
          max_wait = waits.max
          # puts "[#{Time.now.to_f}] Waiting #{max_wait} for #{@tag}"
          `sleep #{max_wait}`
          # puts "[#{Time.now.to_f}] Finished for #{@tag}"
          waits.map { |_w| @tag }
        end
      end

      class Sleeper < GraphQL::Schema::Object
        field :sleeper, Sleeper, null: false, resolver_method: :sleep do
          argument :duration, Float
        end

        def sleep(duration:)
          `sleep #{duration}`
          duration
        end

        field :duration, Float, null: false
        def duration; object; end
      end

      class Waiter < GraphQL::Schema::Object
        field :wait_for, Waiter, null: false do
          argument :tag, String
          argument :wait, Float
        end

        def wait_for(tag:, wait:)
          dataloader.with(WaitForSource, tag).load(wait)
        end

        field :tag, String, null: false
        def tag
          object
        end
      end

      class Query < GraphQL::Schema::Object
        field :sleep, Float, null: false do
          argument :duration, Float
        end

        field :sleeper, Sleeper, null: false, resolver_method: :sleep do
          argument :duration, Float
        end

        def sleep(duration:)
          `sleep #{duration}`
          duration
        end

        field :wait_for, Waiter, null: false do
          argument :tag, String
          argument :wait, Float
        end

        def wait_for(tag:, wait:)
          dataloader.with(WaitForSource, tag).load(wait)
        end
      end

      query(Query)
      use GraphQL::Dataloader::AsyncDataloader
    end

    module AsyncDataloaderAssertions
      def self.included(child_class)
        child_class.class_eval do
          it "runs IO in parallel by default" do
            dataloader = async_schema.dataloader_class.new
            results = {}
            dataloader.append_job { sleep(0.1); results[:a] = 1 }
            dataloader.append_job { sleep(0.2); results[:b] = 2 }
            dataloader.append_job { sleep(0.3); results[:c] = 3 }

            assert_equal({}, results, "Nothing ran yet")
            started_at = Time.now
            dataloader.run
            ended_at = Time.now

            assert_equal({ a: 1, b: 2, c: 3 }, results, "All the jobs ran")
            assert_in_delta 0.3, ended_at - started_at, 0.05, "IO ran in parallel"
          end

          it "works with sources" do
            dataloader = async_schema.dataloader_class.new
            r1 = dataloader.with(AsyncSchema::SleepSource).request(0.1)
            r2 = dataloader.with(AsyncSchema::SleepSource).request(0.2)
            r3 = dataloader.with(AsyncSchema::SleepSource).request(0.3)

            v1 = nil
            dataloader.append_job {
              v1 = r1.load
            }
            started_at = Time.now
            dataloader.run
            ended_at = Time.now
            assert_equal 0.3, v1
            started_at_2 = Time.now
            # These should take no time at all since they're already resolved
            v2 = r2.load
            v3 = r3.load
            ended_at_2 = Time.now

            assert_equal 0.3, v2
            assert_equal 0.3, v3
            assert_in_delta 0.0, started_at_2 - ended_at_2, 0.05, "Already-loaded values returned instantly"

            assert_in_delta 0.3, ended_at - started_at, 0.05, "IO ran in parallel"
          end

          it "works with GraphQL" do
            started_at = Time.now
            res = async_schema.execute("{ s1: sleep(duration: 0.1) s2: sleep(duration: 0.2) s3: sleep(duration: 0.3) }")
            ended_at = Time.now
            assert_equal({"s1"=>0.1, "s2"=>0.2, "s3"=>0.3}, res["data"])
            assert_in_delta 0.3, ended_at - started_at, 0.05, "IO ran in parallel"
          end

          it "nested fields don't wait for slower higher-level fields" do
            query_str = <<-GRAPHQL
            {
              s1: sleeper(duration: 0.1) {
                sleeper(duration: 0.1) {
                  sleeper(duration: 0.1) {
                    duration
                  }
                }
              }
              s2: sleeper(duration: 0.2) {
                sleeper(duration: 0.1) {
                  duration
                }
              }
              s3: sleeper(duration: 0.3) {
                duration
              }
            }
            GRAPHQL
            started_at = Time.now
            res = async_schema.execute(query_str)
            ended_at = Time.now

            expected_data = {
              "s1" => { "sleeper" => { "sleeper" => { "duration" => 0.1 } } },
              "s2" => { "sleeper" => { "duration" => 0.1 } },
              "s3" => { "duration" => 0.3 }
            }
            assert_equal expected_data, res["data"]
            assert_in_delta 0.3, ended_at - started_at, 0.06, "Fields ran without any waiting"
          end

          it "runs dataloaders in parallel across branches" do
            query_str = <<-GRAPHQL
            {
              w1: waitFor(tag: "a", wait: 0.2) {
                waitFor(tag: "b", wait: 0.2) {
                  waitFor(tag: "c", wait: 0.2) {
                    tag
                  }
                }
              }
              # After the first, these are returned eagerly from cache
              w2: waitFor(tag: "a", wait: 0.2) {
                waitFor(tag: "a", wait: 0.2) {
                  waitFor(tag: "a", wait: 0.2) {
                    tag
                  }
                }
              }
              w3: waitFor(tag: "a", wait: 0.2) {
                waitFor(tag: "b", wait: 0.2) {
                  waitFor(tag: "d", wait: 0.2) {
                    tag
                  }
                }
              }
              w4: waitFor(tag: "e", wait: 0.6) {
                tag
              }
            }
            GRAPHQL
            started_at = Time.now
            res = async_schema.execute(query_str)
            ended_at = Time.now

            expected_data = {
              "w1" => { "waitFor" => { "waitFor" => { "tag" => "c" } } },
              "w2" => { "waitFor" => { "waitFor" => { "tag" => "a" } } },
              "w3" => { "waitFor" => { "waitFor" => { "tag" => "d" } } },
              "w4" => { "tag" => "e" }
            }
            assert_equal expected_data, res["data"]
            # We've basically got two options here:
            # - Put all jobs in the same queue (fields and sources), but then you don't get predictable batching.
            # - Work one-layer-at-a-time, but then layers can get stuck behind one another. That's what's implemented here.
            assert_in_delta 1.0, ended_at - started_at, 0.06, "Sources were executed in parallel"
          end
        end
      end
    end

    describe "with async" do
      let(:async_schema) { AsyncSchema }
      include AsyncDataloaderAssertions
    end

    describe "with working_queue_size: ..." do
      let(:async_schema) {
        Class.new(AsyncSchema) do
          use GraphQL::Dataloader::AsyncDataloader, working_queue_size: 5
        end
      }
      include AsyncDataloaderAssertions

      it "runs async when the jobs doesn't exceed the fiber limit" do
        dataloader = async_schema.dataloader_class.new

        async_schema.dataloader_class.working_queue_size.times do |i|
          dataloader.append_job { sleep(0.5) }
        end
        t1 = Time.now
        dataloader.run
        t2 = Time.now
        assert_in_delta 0.5, t2 - t1, 0.06, "There was one pass of waiting 0.5s"
      end

      it "waits for fibers to be available when the number of jobs exceeds the number of fibers" do
        dataloader = async_schema.dataloader_class.new
        working_queue_size_config = async_schema.dataloader_class.working_queue_size
        (working_queue_size_config + 1).times do |i|
          dataloader.append_job { sleep(0.5) }
        end
        t1 = Time.now
        dataloader.run
        t2 = Time.now
        assert_in_delta 1, t2 - t1, 0.06, "There were two passes of waiting 0.5s"

        (working_queue_size_config * 3).times do |i|
          dataloader.append_job { sleep(0.3) }
        end
        t1 = Time.now
        dataloader.run
        t2 = Time.now
        assert_in_delta 0.9, t2 - t1, 0.06, "There were three passes of waiting 0.3s"
      end

      it "limits source calls within jobs" do
        dataloader = async_schema.dataloader_class.new
        results = []
        dataloader.append_job { results[0] = dataloader.with(AsyncSchema::WaitForSource, :t1).load(0.2) }
        dataloader.append_job { results[1] = dataloader.with(AsyncSchema::WaitForSource, :t2).load(0.2) }
        dataloader.append_job { results[2] = dataloader.with(AsyncSchema::WaitForSource, :t3).load(0.2) }
        dataloader.append_job { results[3] = dataloader.with(AsyncSchema::WaitForSource, :t4).load(0.2) }
        dataloader.append_job { results[4] = dataloader.with(AsyncSchema::WaitForSource, :t5).load(0.2) }
        dataloader.append_job { results[5] = dataloader.with(AsyncSchema::WaitForSource, :t6).load(0.2) }

        started_at = Time.now
        dataloader.run
        ended_at = Time.now
        assert_equal [:t1, :t2, :t3, :t4, :t5, :t6], results, "All values were resolved"
        assert_in_delta 0.4, ended_at - started_at, 0.05, "Sources were resolved all at once"
      end

      it "doesn't limit fibers for sources outside of jobs" do
        dataloader = async_schema.dataloader_class.new
        r1 = dataloader.with(AsyncSchema::WaitForSource, :t1).request(0.2)
        r2 = dataloader.with(AsyncSchema::WaitForSource, :t2).request(0.2)
        r3 = dataloader.with(AsyncSchema::WaitForSource, :t3).request(0.2)
        r4 = dataloader.with(AsyncSchema::WaitForSource, :t4).request(0.2)
        r5 = dataloader.with(AsyncSchema::WaitForSource, :t5).request(0.2)
        r6 = dataloader.with(AsyncSchema::WaitForSource, :t6).request(0.2)

        results = []
        dataloader.append_job { results[0] = r1.load }
        dataloader.append_job { results[1] = r2.load }
        dataloader.append_job { results[2] = r3.load }
        dataloader.append_job { results[3] = r4.load }
        dataloader.append_job { results[4] = r5.load }
        dataloader.append_job { results[5] = r6.load }

        started_at = Time.now
        dataloader.run
        ended_at = Time.now
        assert_equal [:t1, :t2, :t3, :t4, :t5, :t6], results, "All values were resolved"
        assert_in_delta 0.2, ended_at - started_at, 0.05, "Sources were resolved all at once"
      end
    end

    describe "removing working_queue_size" do
      it "makes no limit" do
        unlimited_dataloader = Class.new(GraphQL::Dataloader::AsyncDataloader)
        unlimited_dataloader.working_queue_size = nil
        dataloader = unlimited_dataloader.new
        results = []
        100.times do |i|
          dataloader.append_job { sleep(0.2); results[i] = i }
        end
        t1 = Time.now
        dataloader.run
        t2 = Time.now
        assert_equal 100, results.size
        assert_equal results, results.uniq
        assert_in_delta 0.2, t2 - t1, 0.05
      end
    end
  end
end
