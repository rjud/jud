class Object
  def boolean?
    (self.is_a? TrueClass) || (self.is_a? FalseClass)
  end
end

def subsubclasses cl
  return ObjectSpace.each_object(Class).select { |klass| klass < cl }
end
