#!/usr/bin/env ruby

require 'fileutils'

def main
  direc = File.absolute_path(File.dirname(__FILE__))
  print "\n\n"

  src_ver = ARGV.shift
  src_path = ARGV.shift
  force_yard = ARGV.delete('--force')

  if !src_ver || src_ver !~ /^\d\d$/ || (src_path=File.expand_path(src_path)) && !File.directory?(src_path)
    STDERR.puts "syntax:\n  ruby #{__FILE__}  24 /path/to/rubydev_dir  [--force]"
    return
  end
  puts "Source path:#{src_path} \nGenerate the Ruby #{src_ver} docs.."

  Dir.chdir(direc)
  Dir.glob("lib/pry-doc/core_docs_??").each do |di|
    system "git rm -r --cache #{di}"
  end
  docpath = "lib/pry-doc/core_docs_#{src_ver}"

  Dir.chdir(src_path) do
    if File.directory?('.yardoc') && !force_yard
      puts "Already has .yardoc directory,  skip generate!"
    else
      FileUtils.rm_rf('.yardoc')
      system %{
        bash -c "paste <(find . -maxdepth 1 -name '*.c') <(find ext -name '*.c') |
          xargs yardoc --no-output"
      }
    end
    FileUtils.rm_rf("#{direc}/#{docpath}")
    FileUtils.cp_r(".yardoc", "#{direc}/#{docpath}")
  end
  system "git add #{docpath}"

  print "\n\ngem build *.gemspec\n"
  system "gem build *.gemspec"

  print "\n\nls *.gem\n"
  puts Dir.glob('*.gem')
  puts 'end.'
end

if __FILE__ == $0
  main
end

