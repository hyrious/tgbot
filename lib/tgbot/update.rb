require 'faraday'
require 'mimemagic'
module Tgbot
  class Update
    attr_accessor :bot, :update, :type, :done, :count
    def initialize bot, update
      @bot, @update = bot, update
      @type         = get_type
      @done         = false
      @count        = 0
    end
    alias done? done
    def id
      @update.update_id
    end
    def chat_id
      @update[@type].chat&.id
    end
    def text
      @update[@type].text
    end
    def done!
      @done = true
    end
    def retry n = 1
      @done = false if @count < n
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
    %i(photo audio document video voice video_note).each do |name|
      class_eval %{
        def send_#{name}(#{name} = nil, **kwargs)
          return unless chat_id
          return unless #{name} = #{name} || kwargs.delete(:#{name})
          @bot.send_#{name}(
            chat_id: chat_id,
            #{name}: Faraday::UploadIO.new(#{name}, MimeMagic.by_path(#{name}).type),
            **kwargs)
        end
        def reply_#{name}(#{name} = nil, **kwargs)
          return unless chat_id
          return unless #{name} = #{name} || kwargs.delete(:#{name})
          @bot.send_#{name}(
            chat_id: chat_id,
            #{name}: Faraday::UploadIO.new(#{name}, MimeMagic.by_path(#{name}).type),
            reply_to_message_id: @update[@type].message_id, **kwargs)
        end
      }
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
    def inspect
      "#<Update ##{id} #{@type}=#{@update[@type]}>"
    end
    alias to_str inspect
    alias to_s inspect
  end
end
