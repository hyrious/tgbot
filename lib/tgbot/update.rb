module Tgbot
  class Update
    attr_accessor :bot, :update, :type, :life
    def initialize bot, update
      @bot, @update = bot, update
      @type = get_type
      @life = 1
    end
    def done!
      @life = 0
    end
    def done?
      @life <= 0
    end
    def chat_id
      @update[@type].chat&.id
    end
    def text
      @update[@type].text
    end
    def send_message(text = nil, **kwargs)
      return unless chat_id
      return unless text = text || kwargs.delete(:text)
      @bot.send_message(chat_id: chat_id, text: text, **kwargs)
    end
    def reply_message(text = nil, **kwargs)
      return unless chat_id
      return unless text = text || kwargs.delete(:text)
      @bot.send_message(
        chat_id: chat_id, text: text, 
        reply_to_message_id: @update[@type].message_id, **kwargs)
    end
    def get_type
      %i(
        message
        edited_message
        channel_post
        edited_channel_post
        inline_query
        chosen_inline_result
        callback_query
        shipping_query
        pre_checkout_query
      ).find { |f| @update[f] }
    end
    def method_missing(field)
      @update[field]
    end
  end
end
