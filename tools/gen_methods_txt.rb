require 'json'

methods = JSON.load File.read 'methods.json'
ans = methods.map { |method, decl|
  ret, params = decl['ret'], decl['params']
  max_length = [params.keys.map(&:length).max || 0, method.length - 4].max
  patch = -> x { if x.is_a? Array and x.size > 1 then x.join('|') else x end }
  <<~EOF
    #{"%-#{max_length + 4}s" % method} #{patch[ret].inspect.delete('"')}
      #{params.map { |param, attr|
        "#{attr['optional'] ? ' ' : '*'} #{"%-#{max_length}s" % param} #{patch[attr['type']].inspect.delete('"')}"
      }.join("\n  ")}
  EOF
}.join("\n")
open 'methods.txt', 'w' do |f| f.write ans end
