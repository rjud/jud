require 'make'
require 'cl'

module Jud::Tools
  class NMake < Make
    
    # See Cl.configure for NMake configuration.
    
    def initialize options={}
      super options
    end
    
  end
end
