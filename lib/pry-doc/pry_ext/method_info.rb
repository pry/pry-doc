class Pry
  module MethodInfo
    class << self
      ##
      # Retrieve the YARD object that contains the method data.
      # @param [Method, UnboundMethod] meth The method object.
      # @return [YARD::CodeObjects::MethodObject] The YARD data for the method.
      def info_for(meth)
        cache(meth)
        registry_lookup(meth)
      end

      ##
      # Retrives aliases of a method
      # @param [Method, UnboundMethod] meth The method object.
      # @return [Array] The aliases of a method if it exists
      #                 otherwise, return empty array
      def aliases(meth)
        host        = meth.owner
        method_type = :instance_method
        methods = (host.instance_methods + host.private_instance_methods).uniq

        methods.select { |m| host.send(method_type, m.to_s) == host.send(method_type, meth.name) }.
          reject { |m| m.to_s == meth.name.to_s }.
          map    { |m| host.send(method_type, m.to_s) }
      end

      ##
      # FIXME: this is unnecessarily limited to ext/ and lib/ folders
      # @return [String] The root folder of a given gem directory.
      def gem_root(dir)
        if index = dir.rindex(/\/(?:lib|ext)(?:\/|$)/)
          dir[0..index-1]
        end
      end

      private

      # Convert a method object into the `Class#method` string notation.
      # @param [Method, UnboundMethod] meth
      # @return [String] The method in string receiver notation.
      # @note This mess is needed in order to support all the modern Rubies. YOU
      #   must figure out a better way to distinguish between class methods and
      #   instance methods.
      def receiver_notation_for(meth)
        match = meth.inspect.match(/\A#<(?:Unbound)?Method: (.+)([#\.].+?)(?:\(.+\))?>\z/)
        owner = meth.owner.to_s.sub(/#<.+?:(.+?)>/, '\1')
        name = match[2]
        name.sub!('#', '.') if match[1] =~ /\A#<Class:/
        owner + name
      end

      # Checks whether method is a singleton (i.e class method)
      # @param [Method, UnboundMethod] meth
      # @param [Boolean] true if singleton
      def is_singleton?(meth)
        receiver_notation_for(meth).include?('.')
      end

      def registry_lookup(meth)
        if (obj = YARD::Registry.at(receiver_notation_for(meth)))
          return obj
        end

        if (aliases = aliases(meth)).any?
          YARD::Registry.at(receiver_notation_for(aliases.first))
        elsif meth.owner == Kernel
          # YARD thinks that some methods are on Object when
          # they're actually on Kernel; so try again on Object if Kernel fails.
          YARD::Registry.at("Object##{meth.name}")
        end
      end

      ##
      # Attempts to find the c source files if method belongs to a gem
      # and use YARD to parse and cache the source files for display
      #
      # @param [Method, UnboundMethod] meth The method object.
      def parse_and_cache_if_gem_cext(meth)
        return unless (gem_dir = find_gem_dir(meth))

        path = "#{gem_dir}/**/*.c"
        return if Dir.glob(path).none?

        puts "Scanning and caching *.c files..."
        YARD.parse(path)
      end

      # @return [Object] The host of the method (receiver or owner).
      def method_host(meth)
        is_singleton?(meth) && Module === meth.receiver ? meth.receiver : meth.owner
      end

      # @param [Method, UnboundMethod] meth The method object.
      # @return [String] root directory path of gem that method belongs to,
      #                  nil if could not be found
      def find_gem_dir(meth)
        host = method_host(meth)

        begin
          host_source_location, _ =  WrappedModule.new(host).source_location
          break if host_source_location != nil
          return unless host.name
          host = eval(host.namespace_name)
        end while host

        # we want to exclude all source_locations that aren't gems (i.e
        # stdlib)
        if host_source_location && host_source_location =~ %r{/gems/}
          gem_root(host_source_location)
        else

          # the WrappedModule approach failed, so try our backup approach
          gem_dir_from_method(meth)
        end
      end

      # Try to guess what the gem name will be based on the name of the module.
      # We try a few approaches here depending on the `guess` parameter.
      # @param [String] name The name of the module.
      # @param [Fixnum] guess The current guessing approach to use.
      # @return [String, nil] The guessed gem name, or `nil` if out of guesses.
      def guess_gem_name_from_module_name(name, guess)
        case guess
        when 0
          name.downcase
        when 1
          name.scan(/[A-Z][a-z]+/).map(&:downcase).join('_')
        when 2
          name.scan(/[A-Z][a-z]+/).map(&:downcase).join('_').sub("_", "-")
        when 3
          name.scan(/[A-Z][a-z]+/).map(&:downcase).join('-')
        when 4
          name
        else
          nil
        end
      end

      # Try to recover the gem directory of a gem based on a method object.
      # @param [Method, UnboundMethod] meth The method object.
      # @return [String, nil] The located gem directory.
      def gem_dir_from_method(meth)
        guess = 0

        host = method_host(meth)
        return unless host.name
        root_module_name = host.name.split("::").first
        while gem_name = guess_gem_name_from_module_name(root_module_name, guess)
          matches = $LOAD_PATH.grep %r{/gems/#{gem_name}} if !gem_name.empty?
          if matches && matches.any?
            return gem_root(matches.first)
          else
            guess += 1
          end
        end

        nil
      end

      ##
      # Caches the file that holds the method.
      #
      # Cannot cache C stdlib and eval methods.
      #
      # @param [Method, UnboundMethod] meth The method object.
      def cache(meth)
        file, _ = meth.source_location

        # Eval methods can't be cached.
        return if file =~ /(\(.*\))|<.*>/

        # No need to cache already cached methods.
        return if registry_lookup(meth)

        unless file
          parse_and_cache_if_gem_cext(meth)
          return
        end

        log.enter_level(Logger::FATAL) do
          YARD.parse(file)
        end
      end
    end
  end
end
