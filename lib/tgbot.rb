require "tgbot/version"

module Tgbot
  def self.run(token, **opts)
    raise NotImplementedError
  end
end
