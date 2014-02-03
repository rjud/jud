require 'compiler'
require 'language'

module Jud
  class C < Language;
    
    class Compiler < Jud::Compiler; end
    
    class << self
      def compiler; return Compiler; end
    end
    
    def initialize
      $platform.get_compiler self
    end
    
  end
end
