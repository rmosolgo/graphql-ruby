# frozen_string_literal.rb

module GraphQL
  class Dataloader
    # This source uses Redis pipelining to execute a bunch of commands.
    #
    # In practice, an application-specific would be more appropriate, because you
    # could choose between commands like GET and MGET, HGETALL and HMGET, etc.
    #
    # But this source is here as an example of what's possible.
    #
    # @example Getting values from a redis connection.
    #
    #   GraphQL::Dataloader::Redis.load($redis, [:get, "some-key"])
    #   GraphQL::Dataloader::Redis.load($redis, [:hgetall, "some-hash-key"])
    #   GraphQL::Dataloader::Redis.load($redis, [:smembers, "some-set-key"])
    #
    class Redis < Dataloader::Source
      def initialize(redis_connection)
        @redis = redis_connection
      end

      def perform(commands)
        results = @redis.pipelined do
          commands.each do |(command, *args)|
            @redis.public_send(command, args)
          end
        end

        commands.each_with_index do |command, idx|
          result = results[idx]
          fulfill(command, result)
        end
      end
    end
  end
end
