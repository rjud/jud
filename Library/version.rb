module Jud
  class Version < Array

    attr_reader :str
    attr_reader :major, :minor, :release
    
    def initialize str
      super(str.split('.').map { |v| v.to_i })
      @str = str
      @major, @minor, @release = self[0], self[1], self[2]
    end
    
    def to_s
      @str
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
