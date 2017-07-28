require 'json'

types = JSON.load File.read 'types.json'
ans = types.map { |type, fields|
  max_length = fields.keys.map(&:length).max
  # haskell (ry
  # <<~EOF
  #   data #{type} = {
  #     #{fields.map { |field, attr|
  #       "#{"%-#{max_length}s" % field} :: #{attr['type'].inspect.delete('"')}"
  #     }.join("\n  ")}
  #   }
  # EOF
  <<~EOF
    #{type}
      #{fields.map { |field, attr|
        "#{attr['optional'] ? ' ' : '*'} #{"%-#{max_length}s" % field} #{attr['type'].inspect.delete('"')}"
      }.join("\n  ")}
  EOF
}.join("\n")
open 'types.txt', 'w' do |f| f.write ans end
