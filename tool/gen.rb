require 'http'
require 'nokogiri'

raw = HTTP.via('127.0.0.1', 1080).get('https://core.telegram.org/bots/api').to_s
nodes = Nokogiri::HTML(raw).at('#dev_page_content').children
ret = [{ name: 'Telegram Bot API', children: [] }]
uplevels = [2]
nodes.each do |node|
  case node.name
  when 'h3', 'h4'
    n = node.name[/\d/].to_i
    while uplevels[-1] >= n
      ret.pop
      uplevels.pop
    end
    ret[-1][:children] << (x = { name: node.content, children: [] })
    ret << x
    uplevels << n
  when 'h6', 'p', 'blockquote', 'pre'
    (ret[-1]['desc'] ||= []) << { name: node.name, content: node.content.strip }
  when 'ul', 'ol'
    (ret[-1]['desc'] ||= []) << { name: node.name, content: node.css('li').map(&:content).map(&:strip) }
  when 'table'
    keys = node.css('th').map(&:content)
    ret[-1]['table'] = node.css('tbody > tr').map do |tr|
      keys.zip(tr.css('td').map(&:content)).to_h
    end
  end
end
ret = JSON.parse JSON.generate ret[0]
require 'psych'
open(File.expand_path('../lib/api.yaml', __dir__), 'wb') { |f| Psych.dump ret, f, line_width: 1<<30 }
