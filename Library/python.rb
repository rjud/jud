require 'compiler'
require 'language'

module Jud
  class Python < Language;
    
    class Compiler < Jud::Compiler; end
    
    class << self
      def compiler; return Compiler; end
    end
    
  end
end
