# Tgbot

[![Gem Version](https://badge.fury.io/rb/tgbot.svg)](https://badge.fury.io/rb/tgbot)
![Bot API Version](https://img.shields.io/badge/Bot%20API-3.6-blue.svg?style=flat-square)
![](https://img.shields.io/badge/License-MIT-lightgrey.svg?style=flat-square)

A tiny but easy-to-use wrapper of [Telegram Bot API](https://core.telegram.org/bots/api).

## Install

    gem install tgbot

## Usage

```ruby
Tgbot.run TOKEN, proxy: 'http://127.0.0.1:1080' do
  on 'start' do
    reply '#{name}, at your service.'
  end
end
```

## Contribute

PRs/issues are welcome.
