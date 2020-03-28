require_relative "show_source_with_c_internals"

class Pry
  module MethodInfo
    # @return [Regexp] a pattern that matches `method_instance.inspect`
    METHOD_INSPECT_PATTERN =
      # Ruby 2.7 changed how #inspect for methods looks like. It attaches param
      # list and source location now. We use 2 Regexps: one is for 2.7+ and the
      # other one is for older Rubies. This way we can modify both of them
      # without the risk of breaking.
      #
      # See: https://bugs.ruby-lang.org/issues/14145
      if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.7.0")
        %r{\A
          \#<
            (?:Unbound)?Method:\s
            (.+) # Method owner such as "BigDecimal"
            ([\#\.].+?) # Method signature such as ".finite?" or "#finite?"
            \(.*\) # Param list
            (?:
              \s/.+\.rb:\d+ # Source location
            )?
            .* # Sometimes there's gibberish like "<main>:0", we ignore that
          >
        \z}x
      else
        %r{\A
          \#<
            (?:Unbound)?Method:\s
            (.+) # Method owner such as "BigDecimal"
            ([\#\.].+?) # Method signature such as ".finite?" or "#finite?"
            (?:
              \(.*\) # Param list
            )?
          >
        \z}x
      end

    class << self
      ##
      # Retrieve the YARD object that contains the method data.
      #
      # @param [Method, UnboundMethod] meth The method object
      # @return [YARD::CodeObjects::MethodObject] the YARD data for the method
      def info_for(meth)
        cache(meth)
        registry_lookup(meth)
      end

      ##
      # Retrieves aliases of the given method.
      #
      # @param [Method, UnboundMethod] meth The method object
      # @return [Array<UnboundMethod>] the aliases of the given method if they
      #   exist, otherwise an empty array
      def aliases(meth)
        owner = meth.owner
        name = meth.name

        (owner.instance_methods + owner.private_instance_methods).uniq.map do |m|
          aliased_method = owner.__send__(:instance_method, m)

          next unless aliased_method == owner.__send__(:instance_method, name)
          next if m == name
          aliased_method
        end.compact!
      end

      ##
      # FIXME: this is unnecessarily limited to ext/ and lib/ directories.
      #
      # @return [String] the root directory of a given gem directory
      def gem_root(dir)
        return unless (index = dir.rindex(%r(/(?:lib|ext)(?:/|$))))
        dir[0..index-1]
      end

      private

      ##
      # Convert a method object into the `Class#method` string notation.
      #
      # @param [Method, UnboundMethod] meth
      # @return [String] the method in string receiver notation
      # @note This mess is needed to support all the modern Rubies. Somebody has
      #   to figure out a better way to distinguish between class methods and
      #   instance methods.
      def receiver_notation_for(meth)
        match = meth.inspect.match(METHOD_INSPECT_PATTERN)
        owner = meth.owner.to_s.sub(/#<.+?:(.+?)>/, '\1')
        name = match[2]
        name.sub!('#', '.') if match[1] =~ /\A#<Class:/
        owner + name
      end

      ##
      # Checks whether `meth` is a class method.
      #
      # @param [Method, UnboundMethod] meth The method to check
      # @return [Boolean] true if singleton, otherwise false
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
          YARD::Registry.at("Kernel##{meth.name}") ||
            YARD::Registry.at("Object##{meth.name}")
        end
      end

      ##
      # Attempts to find the C source files if method belongs to a gem and use
      # YARD to parse and cache the source files for display.
      #
      # @param [Method, UnboundMethod] meth The method object
      def parse_and_cache_if_gem_cext(meth)
        return unless (gem_dir = find_gem_dir(meth))

        path = "#{gem_dir}/**/*.c"
        return if Dir.glob(path).none?

        puts "Scanning and caching *.c files..."
        YARD.parse(path)
      end

      ##
      # @return [Object] the host of the method (receiver or owner)
      def method_host(meth)
        is_singleton?(meth) && Module === meth.receiver ? meth.receiver : meth.owner
      end

      ##
      # @param [Method, UnboundMethod] meth The method object
      # @return [String, nil] root directory path of gem that method belongs to
      #   or nil if could not be found
      def find_gem_dir(meth)
        host = method_host(meth)

        begin
          host_source_location, _ =  WrappedModule.new(host).source_location
          break if host_source_location != nil
          return unless host.name
          host = eval(namespace_name(host))
        end while host

        # We want to exclude all source_locations that aren't gems (i.e
        # stdlib).
        if host_source_location && host_source_location =~ %r{/gems/}
          gem_root(host_source_location)
        else
          # The WrappedModule approach failed, so try our backup approach.
          gem_dir_from_method(meth)
        end
      end

      ##
      # Try to guess what the gem name will be based on the name of the module.
      #
      # @param [String] name The name of the module
      # @return [Enumerator] the enumerator which enumerates on possible names
      #   we try to guess
      def guess_gem_name(name)
        scanned_name = name.scan(/[A-z]+/).map(&:downcase)

        Enumerator.new do |y|
          y << name.downcase
          y << scanned_name.join('_')
          y << scanned_name.join('_').sub('_', '-')
          y << scanned_name.join('-')
          y << name
        end
      end

      ##
      # Try to recover the gem directory of a gem based on a method object.
      #
      # @param [Method, UnboundMethod] meth The method object
      # @return [String, nil] the located gem directory
      def gem_dir_from_method(meth)
        return unless (host = method_host(meth)).name

        guess_gem_name(host.name.split('::').first).each do |guess|
          matches = $LOAD_PATH.grep(%r(/gems/#{guess}))
          return gem_root(matches.first) if matches.any?
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

      private

      def namespace_name(host)
        host.name.split("::")[0..-2].join("::")
      end
    end
  end
end
