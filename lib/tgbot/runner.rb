require 'json'
require 'ostruct'
require 'tgbot/core'
require 'tgbot/update'

module Tgbot
  class Runner
    attr_accessor :bot, :offset, :timeout, :updates
    def initialize(token, **opts)
      @bot      = Bot.new(token, **opts)
      @offset   = 0
      @timeout  = 2
      @updates  = []
    end
    def mainloop
      loop do
        @updates.each { |u| u.count += 1 }
        update_updates
        @updates.each { |update| yield update }
      end
    end
    def update_updates
      @updates.delete_if(&:done?)
      x = x
      t = time { x = @bot.get_updates offset: @offset + 1, limit: 7, timeout: @timeout }
      case
      when t > @timeout then @timeout += [@timeout / 2, 1].max
      when t < @timeout then @timeout -= 1
      end
      @timeout = [[0, @timeout].max, 15].min
      x['result'].each { |e| @updates.push Update.new(@bot, hash_to_ostruct(e)) } if x['ok']
      @offset = [*@updates.map(&:update_id), @offset].max
    end
    def hash_to_ostruct hash
      JSON.parse JSON.generate(hash), object_class: OpenStruct
    end
    def time
      t = Time.now
      yield
      Time.now - t
    end
    def method_missing(meth, *args, &blk)
      @bot.send(meth, *args, &blk)
    end
  end
end
