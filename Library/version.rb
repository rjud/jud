module Jud
  class Version < Array
    
    attr_reader :major, :minor, :release
    
    def initialize str
      super(str.split('.').map { |v| v.to_i })
      @major, @minor, @release = self[0], self[1], self[2]
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
