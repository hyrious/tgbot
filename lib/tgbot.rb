require 'json'
require 'tgbot/version'
require 'tgbot/core'

module Tgbot
  def self.run(token, **opts)
    raise NotImplementedError
  end
end
