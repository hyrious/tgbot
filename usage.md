# Tgbot.Usage

Since the implementation is so tiny, you can just review source
code to understand usage.

## Example and Explanation

### Hello world

```ruby
Tgbot.run TOKEN, proxy: 'https://127.0.0.1:1080' do |bot|
  bot.get 'hello' do reply 'world' end
end
```

This can be broken into: (with the same effect)

```ruby
bot = Tgbot::DSL.new TOKEN, proxy: 'https://127.0.0.1:1080'
bot.get 'hello' do reply 'world' end
bot.run
```

Here the "`bot`" is actually an instance of `Tgbot::DSL`.

### MainLoop Model

Original Model:

```ruby
loop { updates = get_updates; updates.each { |update| ... } }
```

Only deal with `Update`:

```ruby
loop_get_updates { |update| ... }
```

Which is our `mainloop`: (see [runner.rb#L15](lib/tgbot/runner.rb#L15))

```ruby
mainloop { |update| ... }
```

### DSL

```ruby
bot.start { puts "#{bot.name}, at your service" }
bot.finish { puts "byebye." }
bot.before { |update| puts "Processing ##{update.id}." }
bot.after { |update| puts "Processed ##{update.id}." }
bot.on /\.r(\d+)?d(\d+)?/ do |matched|
  p self #=> #<Update id=123456789>
  t = matched[1]&.to_i || 1
  n = matched[2]&.to_i || 6
  reply _ = Array.new(t){rand n}.to_s rescue 'bad roll!'
end
bot.get 'cuxia', 'blind' do
  name = message&.from&.first_name
  next unless name
  send_message "#{name} cuxia!"
  if rand < 0.5
    self.retry 2 #=> at most retry 2 times, default 1 if not given arg
  end
  done! #=> prevent any retry, mark and drop
end
bot.alias 'cuxia', 'woc', 'wodemaya'
```

- start: will be run once when `bot.run`.
- finish: will be run once when <kbd>Ctrl</kbd><kbd>C</kbd>.
- before: do something with every `Update` before processing.
- after: do something with every `Update` after processing.
- on/get: match text and execute code in `Update` instance.

As you can see, the dsl is still weak. Wish for your idea!

### Call Bot API

You can call bot API at any place with `bot.`.

```ruby
p bot.get_me
bot.get 'debug' do
  p bot.get_me
end
```

Params and returns are Hash.

### Upgrade Bot API

- Edit [types.txt](tools/types.txt) or [methods.txt](tools/methods.txt).
- `rake json`
