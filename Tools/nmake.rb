require 'make'
require 'cl'

class NMake < Make
  
  NMake.configure
  
  def initialize options = {}
    super()
  end
  
end
