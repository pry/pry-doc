class Sample
  # ruby method
  def some_meth; end

  # fake c methods
  def unlink; end
  alias :remove :unlink

  module A
    module B
      # fake c method
      def unlink; end
    end
  end

end
