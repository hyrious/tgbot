require "bundler/gem_tasks"

desc 'Make lib/*.json'
task :json do
  cd 'tools'
  ruby 'gen_types_json.rb'
  cp 'types.json', '../lib'
  ruby 'gen_methods_json.rb'
  cp 'methods.json', '../lib'
end
