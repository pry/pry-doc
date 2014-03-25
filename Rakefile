project_name = "pry-doc"
gem_version  = File.read("VERSION").strip

task :build do
  system "gem build .gemspec"
end
 
task :release => :build do
  system "gem push #{project_name}-#{gem_version}.gem"
end

task :install => :build do
  system "gem install #{project_name}-#{gem_version}.gem"
end