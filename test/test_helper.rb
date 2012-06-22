direc = File.dirname(__FILE__)

class C
  def message; end
end

unless File.exists?("#{direc}/gem_with_cext/ext/Makefile")
  puts
  puts "Building Sample Gem with C Extensions for testing.."
  system("cd #{direc}/gem_with_cext/ext/ && ruby extconf.rb && make")
  puts
end

