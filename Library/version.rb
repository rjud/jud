module Jud
  class Version < Array
    
    def initialize str
      super(str.split('.').map { |v| v.to_i })
    end
    
    def < v
      (self <=> v) < 0
    end
    
    def > v
      (self <=> v) > 0
    end
    
    def == v
      (self <=> v) == 0
    end
    
  end
end
