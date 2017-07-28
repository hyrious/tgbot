require 'json'

raw = File.read 'types.txt'
ans = JSON.generate raw.split("\n\n").map { |raw_type|
  type, *fields = *raw_type.lines.map(&:strip).delete_if(&:empty?).map(&:split)
  {
    type[0] => fields.map { |e|
      case e.size
      when 2 then [e[0], { type: e[1], optional: true  }]
      when 3 then [e[1], { type: e[2], optional: false }]
      end
    }.to_h
  }
}.inject(&:merge)
open 'types.json', 'w' do |f| f.write ans end
