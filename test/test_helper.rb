class C
  def message; end
end

def mock_cext_method(meth)
  meth.instance_eval { def source_location; nil; end }
  meth
end
