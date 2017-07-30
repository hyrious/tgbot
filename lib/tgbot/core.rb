require 'json'
require 'faraday'

module Tgbot
  API_URL = 'https://api.telegram.org'.freeze
  TYPES   = JSON.parse(File.read File.expand_path '../types.json'  , __dir__).freeze
  METHODS = JSON.parse(File.read File.expand_path '../methods.json', __dir__).freeze
  
  # This bot supports a minimal usage of Telegram Bot APIs.
  #   bot = Bot.new TOKEN, proxy: 'https://127.0.0.1:1080'
  #
  # API's methods' input and output are hash.
  #   bot.get_updates offset: 0 #=> { 'ok' => 'true', 'result' => [] }
  # 
  # It will check type of params before post method, and
  # if invalid, it will raise an error with detail.
  class Bot
    attr_accessor :token

    # Initialize a bot, and call getMe at once to see if given token is valid.
    # If everything ok, the bot will get its id and name and so on.
    # token :: String = TOKEN of your bot from botfather
    # opts  :: Hash   = Options passed to Faraday.new
    def initialize(token, **opts)
      @token = token
      get_connection(**opts)
      identify_self
    end

    # Get bot's info.
    def identify_self
      x = get_me
      if x['ok']
        @me = x['result']
      else
        raise ArgumentError, 'not found myself, check your token.'
      end
    end

    # Shortcuts for bot's info.
    def id        ; @me && @me['id']        ; end
    def first_name; @me && @me['first_name']; end
    def username  ; @me && @me['username']  ; end
    alias name first_name

    # Connect to API_URL. It will take few seconds.
    # opts :: Hash = Options passed to Faraday.new
    def get_connection(**opts)
      @conn = Faraday.new(url: API_URL, **opts) do |faraday|
        faraday.request :multipart
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
      end
    end

    # Verify methods and params then call(post) it.
    # `:get_me' and `:getMe' are both valid.
    def method_missing(meth, **kwargs)
      camelized_meth = camelize meth
      meth_body = METHODS[camelized_meth]
      super unless meth_body
      ret, params = meth_body.values_at 'ret', 'params'
      kwargs = JSON.parse JSON.generate kwargs
      check_params! kwargs, params
      call camelized_meth, kwargs
    end

    def call meth, kwargs
      JSON.parse @conn.post("/bot#{@token}/#{meth}", kwargs).body
    rescue
      {}
    end

    # Check args to meet method declaration. Raises error if invalid.
    def check_params! kwargs, params
      params.each do |param, info|
        arg = kwargs[param]
        type, optional = info.values_at 'type', 'optional'
        if (arg.nil? && !optional) || (!arg.nil? && !check_type(arg, type))
          raise ArgumentError, "[#{param}] should be #{type}\n#{error_message_of_type type}"
        end
      end
    end

    # Get declaration of type in form of:
    #   User := { id :: Integer, first_name :: String }
    def error_message_of_type type
      (type.delete('[]').split('|') - ['True', 'Boolean', 'Integer', 'Float', 'String']).map { |type|
        "#{type} := { #{TYPES[type].map { |field, info|
          "#{info['optional'] ? '' : '*'}#{field} :: #{info['type']}"
        }.join(', ')} }"
      }.join(' ')
    end

    # Check arg to meet type declaration. Returns false if invalid.
    def check_type arg, type
      case type
      when 'True'    then return arg == true
      when 'Boolean' then return arg == true || arg == false
      when 'Integer' then return arg.is_a? Integer
      when 'Float'   then return arg.is_a? Float
      when 'String'  then return arg.is_a? String
      end
      if type[0] == '['
        return arg.is_a?(Array) ? arg.all? { |a| check_type a, type[1..-2] } : false
      elsif type.include? '|'
        return type.split('|').any? { |t| check_type arg, t }
      end
      return false unless TYPES[type]
      check_params(arg, TYPES[type])
    end

    # Check args to meet method declaration. Returns false if invalid.
    def check_params kwargs, params
      check_params!(kwargs, params)
      true
    rescue
      false
    end

    def get_types
      TYPES.keys.map(&:to_sym)
    end

    def get_methods
      METHODS.keys.map { |e| underscore e }.map(&:to_sym)
    end

    # Transform 'TheName' or 'theName' to 'the_name'.
    def underscore str
      str.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
         .gsub(/([a-z\d])([A-Z])/,'\1_\2').downcase
    end

    # Transform 'the_name' to 'theName'.
    def camelize meth
      ret = String(meth).split('_')
      ret.drop(1).map(&:capitalize!)
      ret.join
    end

    def inspect
      "#<Bot token=#{@token} id=#{id} first_name=#{first_name} username=#{username}>"
    end
  end
end
