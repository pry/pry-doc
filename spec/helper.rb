require 'pry-doc'

RSpec.configure do |c|
  c.order = 'random'
  c.color = true
  c.disable_monkey_patching!
end

direc = File.dirname(__FILE__)

class C
  def message; end
end

puts
puts "Building Sample Gem with C Extensions for testing.."
system("cd #{direc}/gem_with_cext/gems/ext/ && ruby extconf.rb && make")
puts
