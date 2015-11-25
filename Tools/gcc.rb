require 'c'
require 'cxx'
require 'compiler'
require 'version'

module Jud::Tools
  class GCC < Jud::Compiler
    
    include Jud::Languages::C
    include Jud::Languages::Cxx
    
    class << self
      def variants; return [Platform::UNIX]; end    
    end
    
    def initialize config={}
      super config
    end

    def version
      return @version unless @version.nil?
      cmd = "#{path} --version"
      exit_status = Platform.execute cmd, safe: true, keep: 'gcc'
      /(?<ver>\d+.\d+.\d+)/ =~ exit_status[1].first
      @version = Jud::Version.new ver
      @version
    end
    
    def build_name current_build_name, language
      "#{current_build_name}-gcc#{version.major}"
    end
    
  end
end
