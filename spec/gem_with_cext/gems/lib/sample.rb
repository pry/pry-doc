class Sample
  # ruby method
  def some_meth; end

  # aliasing a C method
  alias :bmethod :amethod

  protected

  def amethod_1; end
  alias :bmethod_1 :amethod_1

  private

  def amethod_2; end

  alias :bmethod_2 :amethod_2
end
