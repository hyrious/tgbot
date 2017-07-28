require 'json'

raw = File.read 'methods.txt'
ans = JSON.generate raw.split("\n\n").map { |raw_method|
  method_ret, *decl = *raw_method.lines.map(&:strip).delete_if(&:empty?).map(&:split)
  method, ret = *method_ret
  {
    method => {
      ret: ret,
      params: decl.map { |e|
        case e.size
        when 2 then [e[0], { type: e[1], optional: true  }]
        when 3 then [e[1], { type: e[2], optional: false }]
        end
      }.to_h
    }
  }
}.inject(&:merge)
open 'methods.json', 'w' do |f| f.write ans end
