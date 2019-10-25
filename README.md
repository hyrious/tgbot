# Tgbot

[![Gem Version](https://badge.fury.io/rb/tgbot.svg)](https://badge.fury.io/rb/tgbot)
![Bot API Version](https://img.shields.io/badge/Bot%20API-4.4-blue.svg?style=flat-square)
![](https://img.shields.io/badge/License-MIT-lightgrey.svg?style=flat-square)

A tiny but easy-to-use wrapper of [Telegram Bot API](https://core.telegram.org/bots/api).

## Install

    gem install tgbot

## Usage

```ruby
Tgbot.run TOKEN, proxy: 'http://127.0.0.1:1080' do
  @name = get_me&.result&.first_name
  on 'start' do
    reply "#@name, at your service."
  end
end
# or
bot = Tgbot.new TOKEN, proxy: 'http://127.0.0.1:1080'
bot.on('start'){ reply "#{get_me&.result&.first_name}, at your service." }
bot.run # will block current thread
```

#### `Tgbot.run token, **options do (block) end`

Start a long polling bot.

| argument | type | notes | example |
|----------|------|-------|---------|
| token | `String` | [ask BotFather for one](https://core.telegram.org/bots#generating-an-authorization-token) | `'123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11'` |

| option | type | notes | example |
|--------|------|-------|---------|
| proxy | `String` | http only | `'127.0.0.1:1080'` |

and in that `(block)`:

#### method_missing

Just call the native bot api. e.g. `getMe()` `send_message(chat_id: 123, text: 'hello')`.

Returns an OpenStruct of the replied object. Basically `struct{ok=true,result=...}`.

#### `self.debug = true | false (default)`

Show debug info (every message, matched command).

#### `start do (do sth when it is connected) end`

```ruby
start do
  puts "\e[33m#{get_me&.result&.first_name}\e[32m, at your service."
end
```

#### `finish do (do sth when Ctrl+C) end`

```ruby
finish do
  puts "おやすみなさい"
end
```

#### `on pattern=nil, **options do |match_data, update, task| (block) end`

Match pattern and do something.

| argument | type | notes | example |
|----------|------|-------|---------|
| pattern | `nil` | match all (including inline query etc.) | `on do ... end` |
| - | `String` \| `Regexp` | match all text<sup>1</sup> | `/^r(\d*)d(\d*)(?:\+(\d*))?/` |

<sup>1</sup>: for convenience, the bot's `@username` is trimmed for easilier matching.

e.g. `"hey bot, /r3d6@mybot+1 lol" =>  #<MatchData "/r3d6+1" 1:"3" 2:"6" 3:"1">`.

| option | type | notes | example |
|--------|------|-------|---------|
| name | `String` | just give it a name | `'roll!'` |
| before_all | `true` | set to run before other `on`s matching the same message | `true` |
| after_all | `true` | set to run after other `on`s matching the same message<sup>2</sup><br>you can't set both `before_all` and `after_all` on one command | `true` |

<sup>2</sup>: order is `* -> before2 -> before1 -> other -> after1 -> after2 -> *`.

and in that `(block)`:

#### `debug message`

Puts that message to STDERR when it is in debug mode.

#### `reply *things, **options`

Reply to the matched message.

| argument | type | notes | example |
|----------|------|-------|---------|
| thing | `String` \| can `.to_s` | will use `parse_mode: Markdown` | `'hello world'` |
| - | `IO` | will use `sendPhoto` if it is a photo, etc. | `File.new("a.png")` |

| option | type | notes | example |
|--------|------|-------|---------|
| media | `false` | set to `false` to force `sendDocument` | `'127.0.0.1:1080'` |
| style | `:none` \| `:at` \| `nil` (default) | reply style<sup>3</sup> | `:at` |
| parse_mode, etc. | depends | see [sendMessage](https://core.telegram.org/bots/api#sendmessage) | - |

reply style<sup>3</sup>:

- `:none` : don't add reply info, so the sender won't receive a prompting.
- `:at`: use `[inline mention of a user](tg://user?id=123456789)` in replied message.
- `nil` (default): include `reply_to_message_id` in replied message object.

#### `interrupt!` `done!`

Stop processing this message (if there be further blocks matching it). see `before_all` `after_all`.

#### `retry! n=1`

Enqueue this message again for at most `n` times.

## Contribute

PRs/issues are welcome.
