def subsubclasses cl
  return ObjectSpace.each_object(Class).select { |klass| klass < cl }
end
