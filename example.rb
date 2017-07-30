require './helper'
save_pid
require 'tgbot'
@garage = load_data.shuffle

TOKEN = 
Tgbot.run TOKEN, proxy: 'https://127.0.0.1:1080' do |bot|

  bot.start do
    log "this is \e[33m#{bot.name}\e[32m, master.", 2
  end
  bot.finish do
    log "byebye.", 1
  end
  bot.get 'drive' do |x, update|
    pic = @garage.pop
    log ">> Sending #{File.basename(pic)} to @#{update.message.from.username} ##{update.id}", 6
    update.reply_photo pic, caption: File.basename(pic, '.*')
  end
  bot.before do |update|
    log ">> Processing ##{update.id} #{bot.timeout}"
  end
  bot.after do |update|
    if update.done?
      log "=> Success ##{update.id}", 2
    else
      log "?> Retry ##{update.id}", 3
    end
  end

end

save_data @garage
delete_pid