class Sample
  # ruby method
  def some_meth; end

  # aliasing a C method
  alias :remove :unlink

  protected

  def unlink_1; end
  alias :remove_1 :unlink_1

  private

  def unlink_2; end

  alias :remove_2 :unlink_2
end
