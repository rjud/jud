load "Library/perl.rb"

module Jud::Tools
  class Perl < Jud::Compiler
    
    include Jud::Languages::Perl
    
    def initialize config = {}
      super config
    end
    
  end
end
