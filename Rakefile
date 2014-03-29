project_name = "pry-doc"
gem_version  = File.read("VERSION").strip

desc "Build the gem"
task :build do
  system "gem build .gemspec"
end

desc "Build and push the gem to rubygems.org" 
task :release => :build do
  system "gem push #{project_name}-#{gem_version}.gem"
end

desc "Build and install the gem" 
task :install => :build do
  system "gem install #{project_name}-#{gem_version}.gem"
end

desc "Run bacon specs"
task :spec do
  puts
  puts "Testing #{project_name}-#{gem_version} on Ruby #{RUBY_VERSION}..."
  puts
  sh "bacon -k #{File.dirname(__FILE__)}/spec/pry-doc_spec.rb"
end

task :test    => :spec
task :default => :test
