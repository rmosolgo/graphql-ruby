# frozen_string_literal: true
require "spec_helper"

if Fiber.respond_to?(:scheduler) # Ruby 3+
  describe "GraphQL::Dataloader::AsyncDataloader" do
    class SleepSource < GraphQL::Dataloader::Source
      def fetch(keys)
        max_sleep = keys.max
        @dataloader.do_sleep(max_sleep)
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
        @dataloader.do_sleep(max_wait)
        # puts "[#{Time.now.to_f}] Finished for #{@tag}"
        waits.map { |_w| @tag }
      end
    end

    class Sleeper < GraphQL::Schema::Object
      field :sleeper, Sleeper, null: false, resolver_method: :sleep do
        argument :duration, Float
      end

      def sleep(duration:)
        dataloader.do_sleep(duration)
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
        dataloader.do_sleep(duration)
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


    def with_scheduler
      prev_scheduler = Fiber.scheduler
      Fiber.set_scheduler(nil)
      p "Setting a new scheduler (#{scheduler_class})"
      Fiber.set_scheduler(scheduler_class.new)
      yield
    ensure
      Fiber.set_scheduler(prev_scheduler)
    end

    module AsyncDataloaderAssertions
      def setup
        opts = { nonblocking: true }
        fiber_mode = fiber_control_mode
        if fiber_mode
          opts[:fiber_control_mode] = fiber_mode
        end
        sleepable_mod = sleepable

        custom_dataloader = Class.new(GraphQL::Dataloader) do
          include sleepable_mod
        end
        @async_schema = Class.new(GraphQL::Schema) do
          extend sleepable_mod
          query(Query)
          use custom_dataloader, **opts
        end
      end

      def assert_faster_than(sequential_seconds, actual_seconds, message = nil)
        assert_operator actual_seconds, :<, sequential_seconds, message
      end

      def self.included(child_class)
        child_class.class_eval do
          it "runs IO in parallel by default" do
            dataloader = @async_schema.dataloader_class.new
            results = {}
            dataloader.append_job { @async_schema.do_sleep(0.1); results[:a] = 1 }
            dataloader.append_job { @async_schema.do_sleep(0.2); results[:b] = 2 }
            dataloader.append_job { @async_schema.do_sleep(0.3); results[:c] = 3 }

            assert_equal({}, results, "Nothing ran yet")
            started_at = Time.now
            with_scheduler { dataloader.run }
            ended_at = Time.now

            assert_equal({ a: 1, b: 2, c: 3 }, results, "All the jobs ran")
            assert_faster_than(0.6, ended_at - started_at, "IO ran in parallel")
          end

          it "works with sources" do
            dataloader = @async_schema.dataloader_class.new
            r1 = dataloader.with(SleepSource).request(0.1)
            r2 = dataloader.with(SleepSource).request(0.2)
            r3 = dataloader.with(SleepSource).request(0.3)

            v1 = nil
            dataloader.append_job {
              v1 = r1.load
            }
            started_at = Time.now
            with_scheduler { dataloader.run }
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
            assert_faster_than(0.6, ended_at - started_at, "IO ran in parallel")
          end

          it "works with GraphQL" do
            started_at = Time.now
            res = with_scheduler {
              @async_schema.execute("{ s1: sleep(duration: 0.1) s2: sleep(duration: 0.2) s3: sleep(duration: 0.3) }")
            }
            ended_at = Time.now
            assert_equal({"s1"=>0.1, "s2"=>0.2, "s3"=>0.3}, res["data"])
            assert_faster_than(0.6, ended_at - started_at, "IO ran in parallel")
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
            res = with_scheduler {
              @async_schema.execute(query_str)
            }
            ended_at = Time.now

            expected_data = {
              "s1" => { "sleeper" => { "sleeper" => { "duration" => 0.1 } } },
              "s2" => { "sleeper" => { "duration" => 0.1 } },
              "s3" => { "duration" => 0.3 }
            }
            assert_equal expected_data, res["data"]
            assert_faster_than(0.61, ended_at - started_at, "Fields ran without any waiting")
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
            res = with_scheduler do
              @async_schema.execute(query_str)
            end
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
            # There's a total of 1.0s of sleep; add some extra to allow for overhead
            assert_faster_than(1.31, ended_at - started_at, "Sources were executed in parallel")
          end
        end
      end
    end

    module BacktickSleep
      def do_sleep(duration)
        `sleep #{duration}`
      end
    end

    module SystemSleep
      def do_sleep(duration)
        system("sleep #{duration}")
      end
    end

    describe "With the toy scheduler from Ruby's tests" do
      let(:scheduler_class) { ::DummyScheduler }
      let(:fiber_control_mode) { nil }
      let(:sleepable) { BacktickSleep }
      include AsyncDataloaderAssertions
    end

    if !ENV["GITHUB_ACTIONS"] && RUBY_ENGINE == "ruby"
      describe "With libev_scheduler" do
        require "libev_scheduler"
        let(:scheduler_class) { Libev::Scheduler }
        let(:fiber_control_mode) { nil }
        let(:sleepable) { BacktickSleep }
        include AsyncDataloaderAssertions
      end
    end

    describe "with evt" do
      require "evt"
      let(:scheduler_class) { Evt::Scheduler }
      let(:fiber_control_mode) { nil }
      let(:sleepable) { BacktickSleep }
      include AsyncDataloaderAssertions
    end


    if RUBY_VERSION > "3.2"
      describe "with fiber_scheduler" do
        require "fiber_scheduler"
        let(:scheduler_class) { FiberScheduler }
        let(:fiber_control_mode) { :transfer }
        let(:sleepable) { SystemSleep }
        include AsyncDataloaderAssertions
      end

      describe "with async" do
        require "async"
        let(:scheduler_class) { Async::Scheduler }
        let(:fiber_control_mode) { :transfer }
        let(:sleepable) { SystemSleep }
        include AsyncDataloaderAssertions
      end
    end
  end
end
