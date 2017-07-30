require_relative 'core'
require_relative 'runner'

module Tgbot
  class DSL
    attr_accessor :runner
    def initialize(token, **opts)
      @runner = Runner.new(token, **opts)
      @procs = { command: {} }
    end
    def start(&blk)
      @procs[:start] = blk
    end
    def finish(&blk)
      @procs[:finish] = blk
    end
    def on(regex, &blk)
      @procs[:command][regex] = blk
    end
    alias get on
    def run
      yield self if block_given?
      @procs[:start]&.call
      begin
        @runner.mainloop do |update|
          @procs[:command].each do |key, blk|
            x = update.text&.match key
            blk.call x, update if x
          end
        end
      rescue Interrupt
        @procs[:finish]&.call
      rescue => e
        puts $!
        puts e.backtrace
        retry
      end
    end
    def method_missing(meth, *args, &blk)
      @runner.send(meth, *args, &blk)
    end
  end
  def self.run(token, **opts, &blk)
    DSL.new(token, **opts).run(&blk)
  end
end