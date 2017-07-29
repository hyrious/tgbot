require 'json'
require 'faraday'

module Tgbot
  API_URL = 'https://api.telegram.org'.freeze
  TYPES   = JSON.parse File.read File.expand_path '../types.json'  , __dir__
  METHODS = JSON.parse File.read File.expand_path '../methods.json', __dir__
  class Bot
    attr_accessor :token
    def initialize(token, **opts)
      @token = token
      get_connection(**opts)
      identify_self
    end
    def identify_self
      x = get_me
      if x['ok']
        @me = x['result']
      else
        raise ArgumentError, 'not found myself, checkout your token.'
      end
    end
    def id
      @me && @me['id']
    end
    def first_name
      @me && @me['first_name']
    end
    alias name first_name
    def username
      @me && @me['username']
    end
    def get_connection(**opts)
      @conn = Faraday.new(url: API_URL, **opts) do |faraday|
        faraday.request :multipart
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
      end
    end
    def method_missing(meth, **kwargs)
      meth = camelize meth
      meth_body = METHODS[meth]
      super unless meth_body
      ret, params = meth_body.values_at 'ret', 'params'
      kwargs = JSON.parse JSON.generate kwargs
      check_params! kwargs, params
      call meth, kwargs
    end
    def call meth, kwargs
      JSON.parse @conn.post("/bot#{@token}/#{meth}", kwargs).body
    end
    def check_params! kwargs, params
      params.each do |param, info|
        arg = kwargs[param]
        type, optional = info.values_at 'type', 'optional'
        if (arg.nil? && !optional) || (!arg.nil? && !check_type(arg, type))
          raise ArgumentError, "[#{param}] should be #{type}\n#{error_message_of_type type}"
        end
      end
    end
    def error_message_of_type type
      (type.delete('[]').split('|') - ['True', 'Boolean', 'Integer', 'Float', 'String']).map { |type|
        "#{type} := { #{TYPES[type].map { |field, info|
          "#{info['optional'] ? '' : '*'}#{field} :: #{info['type']}"
        }.join(', ')} }"
      }.join(' ')
    end
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
      end
      return false unless TYPES[type]
      check_params(arg, TYPES[type])
    end
    def check_params kwargs, params
      check_params!(kwargs, params)
      true
    rescue
      false
    end
    def underscore str
      str.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
         .gsub(/([a-z\d])([A-Z])/,'\1_\2').downcase
    end
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
