require 'json'
require 'faraday'
require './helper'
save_pid
require 'tgbot'
Garage = load_data.shuffle
Cache = {}
TOKEN = 
Tgbot.run TOKEN, proxy: 'https://127.0.0.1:1080' do |bot|

  bot.start do
    log "\e[33m#{bot.name}\e[32m, at your service.", 2
  end
  bot.finish do
    log "byebye.", 2
  end

  bot.get 'start' do
    send_message(<<~EOF, parse_mode: 'Markdown')
      ```
      start : 显示此帮助信息
      drive : 随机返回一张车库里的图
              对该图回复 “原图” : 返回原图
      exchange 100 CNY to JPY : 汇率转换
      register : 添加自定义功能（会先提交给作者）
      ```
    EOF
  end

  bot.get 'drive' do
    pic = Garage.pop
    log ">> Sending #{File.basename(pic)} to @#{message.from.username} ##{id}", 6
    bytes = File.size pic
    size = hsize bytes
    reply "正在发车 (#{size} #{htime(bytes / 30720)})"
    x = reply_photo pic, caption: File.basename(pic, '.*')
    if self.done = x['ok']
      Cache["drive_#{x['result']['message_id']}"] = pic
    end
    self.done! if self.count > 1
  end
  bot.get '原图' do
    x = message&.reply_to_message&.message_id
    pic = Cache["drive_#{x}"]
    unless pic
      reply '没找到原图，重开'
      next
    end
    log ">> Sending original #{File.basename(pic)} to @#{message.from.username} ##{id}", 6
    reply_document pic
  end

  bot.get 'exchange' do
    x = text&.match /([-+]?[1-9]\d*(\.\d+)?)\s*([A-Z]+)\s*to\s*([A-Z]+)/
    unless x
      reply 'Usage: exchange 100 CNY to JPY'
      next
    end
    n, f, t = x.values_at 1, 3, 4
    n = Float(n) rescue next
    Cache["exchange_#{f}"] ||= JSON.parse Faraday.get("http://api.fixer.io/latest?base=#{f}").body
    next unless Cache["exchange_#{f}"] && !Cache["exchange_#{f}"]['error']
    next unless Cache["exchange_#{f}"]['rates'][t]
    n *= Cache["exchange_#{f}"]['rates'][t]
    t = Cache["exchange_#{f}"]['date']
    reply "#{'%.2f' % n} (#{t})"
  end

  bot.before do |update|
    log ">> Processing ##{update.id}"
    log "@#{update.message&.from.username}: #{update.text}", 3
  end
  bot.after do |update|
    if update.done?
      log "=> Success ##{update.id}", 2
    else
      log "?> Retry ##{update.id}", 3
    end
  end

  bot.get 'register' do
    e = message&.entities&.find { |e| e.type == 'pre' }
    if e.nil?
      send_message(<<~EOF)
        register <功能名>
        ```
        get /command/ do |matched|
          # your code here
        end
        ```
      EOF
      next
    end
    open 'register.rb', 'a' do |f|
      f.puts text[e.offset, e.length]
    end
    reply '脚本已备分'
  end

  bot.get 'coin' do
    send_message Array.new(text&.match(/\d+/)&.to_s.to_i || 1){ ['🌞', '🌚'].sample }.join
  end
  bot.get 'roll' do
    send_message rand(text&.match(/\d+/)&.to_s.to_i || 100).to_s
  end

end

save_data Garage
delete_pid