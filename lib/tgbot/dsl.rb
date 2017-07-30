require 'ostruct'
require_relative 'core'

module Tgbot
  class DSL
    attr_accessor :bot
    def initialize(token, **opts)
      @bot = Bot.new(token, **opts)
      @procs = {commands: {}}
      @offset  = 0
      @timeout = 2
      @updates = []
    end
    def start(&blk)
      @procs[:start] = blk
    end
    def finish(&blk)
      @procs[:finish] = blk
    end
    def ok str
      puts str
    end
    def on(regex, &blk)
      @procs[:commands][regex] = blk
    end
    alias get on
    def run
      yield self
      @procs[:start]&.call
      begin
        mainloop
      rescue Interrupt
        @procs[:finish]&.call
      rescue => e
        puts $!
        puts e.backtrace
        retry
      end
    end
    def mainloop
      loop do
        update_updates
        @updates.each do |update|
          @procs[:commands].each do |key, blk|
            handle key, update, blk
          end
        end
      end
    end
    def handle key, update, blk
      return unless update.message
      case key
      when String, Regexp
        x = update.message&.text.match key
        blk.call x, update if x
        update.done = true
      end
    end
    def update_updates
      @updates.delete_if(&:done?)
      x = x
      t = time { x = @bot.get_updates offset: @offset + 1, limit: 7, timeout: @timeout }
      case
      when t > @timeout then @timeout *= 2
      when t < @timeout then @timeout -= 1
      end
      @timeout = [[0, @timeout].max, 15].min
      if x['ok']
        x['result'].each do |e|
          @updates.push with_additional_info hash_to_ostruct e
        end
      end
      @offset = [*@updates.map(&:update_id), @offset].max
    end
    def with_additional_info o
      case
      when o.message              then o.type = :message
      when o.edited_message       then o.type = :edited_message
      when o.channel_post         then o.type = :channel_post
      when o.edited_channel_post  then o.type = :edited_channel_post
      when o.inline_query         then o.type = :inline_query
      when o.chosen_inline_result then o.type = :chosen_inline_result
      when o.callback_query       then o.type = :callback_query
      when o.shipping_query       then o.type = :shipping_query
      when o.pre_checkout_query   then o.type = :pre_checkout_query
      end
      o.done = false
      o.instance_eval { alias done? done }
      o
    end
    def hash_to_ostruct hash
      JSON.parse JSON.generate(hash), object_class: OpenStruct
    end
    def ostruct_to_hash ostruct, hash = {}
      ostruct.each_pair do |key, value|
        hash[key] = value.is_a?(OpenStruct) ? ostruct_to_hash(value) : value
      end
      hash
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
  def self.run(token, **opts, &blk)
    DSL.new(token, **opts).run(&blk)
  end
end
