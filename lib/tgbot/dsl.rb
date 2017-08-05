require 'tgbot/runner'

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
    def before(&blk)
      @procs[:before] = blk
    end
    def after(&blk)
      @procs[:after] = blk
    end
    def on(*regexes, &blk)
      regexes.each { |regex| @procs[:command][regex] = blk }
    end
    alias get on
    def alias(ori, *args)
      args.each { |regex| @procs[:command][regex] = @procs[:command][ori] }
    end
    def run
      yield self if block_given?
      @procs[:start]&.call
      begin
        @runner.mainloop do |update|
          @procs[:before]&.call update
          update.done = true
          @procs[:command].each do |key, blk|
            x = update.text&.match key
            update.instance_exec(x, &blk) if x
          end
          @procs[:after]&.call update
        end
      rescue Interrupt
        @procs[:finish]&.call
      rescue => e
        puts e.backtrace.unshift(e.to_s).join("\n")
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
