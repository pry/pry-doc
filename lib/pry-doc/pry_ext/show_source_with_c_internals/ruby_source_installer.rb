module Pry::CInternals
  class RubySourceInstaller
    attr_reader :ruby_version
    attr_reader :ruby_source_folder

    attr_accessor :curl_cmd
    attr_accessor :etag_binary
    attr_accessor :etag_cmd

    def initialize(ruby_version, ruby_source_folder)
      @ruby_version = ruby_version
      @ruby_source_folder = ruby_source_folder

      set_platform_specific_commands
    end

    def install
      ask_for_install
      puts "Downloading and setting up Ruby #{ruby_version} source..."
      download_ruby
      generate_tagfile
      puts "...Finished!"
    end

    private

    def set_platform_specific_commands
      if Pry::Platform.windows?
        self.curl_cmd = "curl -k --fail -L -O https://github.com/ruby/ruby/archive/v#{ruby_version}.zip " +
                        "& 7z -y x v#{ruby_version}.zip"
        self.etag_binary = File.join(PryDoc.root, "libexec/windows/etags")
        self.etag_cmd = %{dir /b /s *.c *.h *.y | "#{etag_binary}" - --no-members}
      else
        self.curl_cmd = "curl --fail -L https://github.com/ruby/ruby/archive/v#{ruby_version}.tar.gz | tar xzvf - 2> /dev/null"
        self.etag_binary = Pry::Platform.linux? ? File.join(PryDoc.root, "libexec/linux/etags-#{arch}") : "etags"
        self.etag_cmd = "find . -type f -name '*.[chy]' | #{etag_binary} - --no-members"
      end
    end

    def ask_for_install
      print "Identifier not found - do you want to install CRuby sources to attempt to resolve the identifier there?" +
            "\nThis allows the lookup of C internals Y/N "

      if $stdin.gets !~ /^y/i
        puts "CRuby sources not installed. To prevent being asked again, add `Pry.config.skip_cruby_source = true` to your ~/.pryrc"
        raise Pry::CommandError, "No definition found."
      end
    end

    def download_ruby
      FileUtils.mkdir_p(ruby_source_folder)
      FileUtils.cd(File.dirname(ruby_source_folder)) do
        %x{ #{curl_cmd} }
        check_for_error(curl_cmd) { Dir.entries(ruby_source_folder).count > 5 }
      end
    end

    # @param [String] message Message to display on error
    # @param [&Block] block Optional assertion
    def check_for_error(message, &block)
      raise Pry::CommandError, message if $?.to_i != 0 || block && !block.call
    end

    def arch
      RbConfig::CONFIG['arch'] =~ /i(3|6)86/ ? 32 : 64
    end

    def generate_tagfile
      FileUtils.cd(ruby_source_folder) do
        puts "Generating tagfile!"
        %x{ #{etag_cmd} }
        check_for_error(etag_cmd) { File.size(File.join(ruby_source_folder, "TAGS")) > 500 }
      end
    end
  end
end
