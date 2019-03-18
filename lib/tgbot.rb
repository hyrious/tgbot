require 'tgbot/version'

require 'http'
require 'ostruct'
require 'json'
require 'psych'

class Tgbot
  APIDOC = Psych.load_file File.join __dir__, 'api.yaml'

  def self.run(*args, &blk)
    bot = new(*args)
    bot.instance_exec(bot, &blk) if blk
    bot.run
  end

  attr_accessor :debug

  def initialize(token, proxy: nil, debug: false)
    @prefix = "/bot#{token}"
    @client = HTTP.persistent "https://api.telegram.org"
    if proxy
      addr, port = *proxy.split(':')
      @client = @client.via(addr, port.to_i)
    end
    @debug = debug
    @commands = []
    @start = @finish = nil
  end

  def start &blk
    @start = blk
  end

  def finish &blk
    @finish = blk
  end

  def on pattern=nil, name: nil, before_all: false, after_all: false, &blk
    if before_all && after_all
      raise ArgumentError, 'before_all and after_all can\'t both be true'
    end
    @commands << [pattern, name, before_all, after_all, blk]
  end

  def debug msg
    STDERR.puts "#{Time.now.strftime "%FT%T"} #{msg}" if @debug
  end

  class Update
    attr_reader :bot, :data

    def initialize bot, data
      @bot = bot
      @data = data
    end

    def interrupt!
      @bot.instance_variable_get(:@tasks).clear
    end

    alias done! interrupt!

    def retry! n=1
      @retried ||= n
      return if @retried <= 0
      @bot.instance_variable_get(:@updates) << self
      @retried -= 1
    end

    def match? pattern
      return true if pattern.nil?
      return false if text.nil?
      !!match(pattern)
    end

    def match pattern
      return nil if pattern.nil? || text.nil?
      pattern.match(text)
    end

    def message
      @data.to_h.find { |k, v| k.match? /message|post/ }&.last
    end

    def text
      message&.text
    end

    def reply *things, media: true, style: nil, **options
      payload = { chat_id: message&.chat.id }
      things.each do |x|
        case x
        when String
          payload[:text] = x
          payload[:parse_mode] = 'Markdown'
        end
      end
      payload = payload.merge options
      case style
      when :at
        if payload[:text] && from
          if payload[:parse_mode].match? /Markdown/i
            prefix = "[#{from.first_name}](tg://user?id=#{from.id}) "
          elsif payload[:parse_mode].match? /HTML/i
            prefix = "<a href=\"tg://user?id=#{from.id}\">#{from.first_name}</a> "
          else
            prefix = ''
          end
          payload[:text] = prefix + payload[:text]
        end
      when nil
        if !payload[:reply_to_message_id]
          payload[:reply_to_message_id] = message_id
        end
      end
      send_message payload
    end

    def message_id
      message&.message_id
    end

    def method_missing meth, *args, &blk
      return @data[meth] if args.empty? && @data[meth]
      @bot.send(meth, *args, &blk)
    end
  end

  def run &blk
    @offset = 0
    @timeout = 2
    @updates = []
    instance_exec(self, &@start) if @start
    loop do
      while x = @updates.shift
        u = Update.new(self, x)
        @tasks = @commands.select { |(pattern, *)| u.match? pattern }
          .group_by { |e| e[2] ? :before : e[3] ? :after : nil }
          .values_at(:before, nil, :after).flatten(1)
        while t = @tasks.shift
          u.instance_exec(u, t, &t[4])
        end
      end
      res = get_updates offset: @offset + 1, limit: 7, timeout: 15
      if res.ok
        @updates.push *res.result
      else
        debug "#{res.error_code}: #{res.description}"
      end
    end
  rescue HTTP::ConnectionError
    debug "connect failed, check proxy?"
    retry
  rescue Interrupt
    instance_exec(self, &@finish) if @finish
  ensure
    @client.close
  end

  def api_version
    search_in_doc(/changes/i, '')[0].desc[0].content[/\d+\.\d+/]
  end

  private

  def method_missing meth, *args, &blk
    meth = meth.to_s.split('_').map.
      with_index { |x, i| i.zero? ? x : (x[0].upcase + x[1..-1]) }.join
    payload = make_payload meth, *args
    debug "/#{meth} #{payload}"
    result = @client.post("#@prefix/#{meth}", form: payload).to_s
    result = json_to_ostruct(result)
    blk ? blk.call(result) : result
  end

  def json_to_ostruct json
    JSON.parse(json, object_class: OpenStruct)
  end

  def make_payload meth, *args
    defaults, schema = meth_info meth
    payload = {}
    args.each do |arg|
      if field = defaults.find { |k, _| k.any? { |l| check_match l, arg } }&.last
        defaults.delete_if { |_, v| v == field }
        pp [field, defaults]
        payload[field] = arg
      end
      if Hash === arg
        payload = payload.merge arg
      end
    end
    if !defaults.empty?
      debug "should 400: #{defaults.values.join(', ')} not specified"
    end
    check_type payload, schema
  end

  def meth_info meth
    unless table = (search_in_doc '', /^#{meth}$/)[0]&.table
      debug "don't find type of #{meth}"
      return {}, {}
    end
    defaults = table.select { |e| e.Required.match? /Yes/i }
      .map { |e|
        [e.Type.split(/\s+or\s+/).flat_map { |s| 
          string_to_native_types s, false
        }.compact, e.Parameter]
      }.reject { |(ts, _para)| ts.empty? }.to_h
    schema = table
      .map { |e|
        [e.Parameter, e.Type.split(/\s+or\s+/).map { |s|
          string_to_native_types s
        }]
      }.to_h
    return defaults, schema
  end

  def string_to_native_types s, keep_unknown=true
    if s['Array of ']
      return [string_to_native_types(s[9..-1], keep_unknown)]
    end
    case s
    when 'String'  then String
    when 'Integer' then Integer
    when 'Boolean' then [true, false]
    else
      keep_unknown ? s : nil
    end
  end

  def check_match k, arg
    if Array === k
      if k.size > 1
        k.any? { |t| t === arg }
      else
        Array === arg && arg.all? { |a| check_match k[0], a }
      end
    else
      return true if String === k # unknown types, like "User"
      k === arg
    end
  end

  def check_type payload, schema
    filtered = {}
    payload.each do |field, value|
      row = schema[field.to_s]
      if row&.any? { |k| check_match k, value }
        filtered[field] = value
      else
        debug "check_type failed at #{field} :: #{row&.join(' | ')} = #{value.inspect}"
      end
    end
    filtered
  end

  def search_in_doc *hints
    doc = [APIDOC]
    hints.each do |hint|
      if nxt = doc.flat_map { |x| x['children'] }.select { |x| x['name'][hint] }
        doc = nxt
      else
        return nil
      end
    end
    json_to_ostruct JSON.generate doc
  end
end
