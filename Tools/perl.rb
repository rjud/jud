load "Library/perl.rb"
require 'compiler'

module Jud::Tools
  class Perl < Jud::Compiler
    
    include Jud::Languages::Perl
    
    def initialize config = {}
      super config
    end
    
  end
end
