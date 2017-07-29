require 'json'
require 'faraday'

module Telegram
  class Bot
    API_URL = 'https://api.telegram.org'.freeze
    TYPES   = JSON.parse File.read File.expand_path '../data/types.json'  , __dir__
    METHODS = JSON.parse File.read File.expand_path '../data/methods.json', __dir__
    attr_accessor :token
    def initialize(token, **opts)
      @token = token
      get_connection(**opts)
    end
    def get_connection(**opts)
      @conn = Faraday.new(url: API_URL, **opts) do |faraday|
        faraday.request :multipart
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
      end
    end
    def method_missing(meth, **kwargs)
      meth = METHODS[camelize meth]
      super unless meth
      ret, params = meth.values_at 'ret', 'params'
      kwargs = JSON.parse JSON.generate kwargs
      check_params(kwargs, params)
      call meth, kwargs
    end
    def check_params(kwargs, params)
      params.each do |param, info|
        kwargs[param]
      end
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
  end
end

p Telegram::Bot::METHODS['getUpdates']
