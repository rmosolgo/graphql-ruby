# frozen_string_literal: true
class MockPusher
  class Channel
    attr_reader :id, :occupants

    def initialize(id)
      @id = id
      @occupants = 0
      @inboxes = [[]]
    end

    def trigger(event_name, payload)
      if event_name != "update"
        raise "Invariant: GraphQL is only expected to call update, but received #{event_name.inspect}. Fix tests or implementation."
      end
      @inboxes.each do |ibx|
        ibx << payload
      end
      nil
    end

    def new_inbox
      ibx = []
      @inboxes << ibx
      ibx
    end

    def updates
      @inboxes[0]
    end

    def occupant_left
      @occupants -= 1
      if @occupants < 0
        raise "Invariant: less than 0 occupants for #{self.inspect}"
      end
      nil
    end

    def occupant_entered
      @occupants += 1
      nil
    end

    def occupied?
      @occupants > 0
    end
  end

  def initialize
    @channels = Hash.new { |h, k| h[k] = Channel.new(k) }
    @key = "abcdef"
    @secret = "12345"
    @batch_sizes = []
  end

  attr_reader :key, :secret, :batch_sizes

  # Mock pusher:
  def channel_info(channel_name, info: "")
    channel = @channels[channel_name]
    res = { occupied: channel.occupied? }
    if info.include?("subscription_count")
      res[:subscription_count] = channel.occupants
    end
    res
  end

  def trigger(channel_name, action, payload)
    @channels[channel_name].trigger(action, payload)
  end

  def trigger_batch(triggers)
    @batch_sizes << triggers.size
    triggers.each do |trigger|
      @channels[trigger[:channel]].trigger(trigger[:name], trigger[:data])
    end
  end

  # Testing:
  def channel(channel_name)
    @channels[channel_name]
  end
end
