require 'make'
require 'cl'

class NMake < Make
  
  NMake.configure
  
  def initialize name, options = {}
    super(name)
  end
  
end
