require 'tgbot'

TOKEN = 

Tgbot.run TOKEN, proxy: 'https://127.0.0.1:1080' do |bot|

  bot.start do
    puts "this is #{bot.name}, master."
  end
  bot.finish do
    puts "byebye."
  end
  bot.on(/roll\s+(\d+)/) do |matched, update|
    update.reply_message String(rand _ = Integer(matched[1]) rescue 100)
  end
  bot.on(/echo\s(.+)$/) do |matched, update|
    update.reply_message matched[1]
  end
  bot.before do |update|
    puts "Processing ##{update.id}"
  end
  bot.after do |update|
    puts "[ #{update.done? ? 'O' : 'X'} ] ##{update.id}"
  end

end
