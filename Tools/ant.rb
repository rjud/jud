require 'build_tool'

module Jud::Tools
  class Ant < BuildTool
    
    class << self

      def configure
        old_pathext = ENV['PATHEXT']
        ENV['PATHEXT'] = '.BAT'
        super
        ENV['PATHEXT'] = old_pathext
      end
      
    end
    
    attr_reader :ant_home
    
    def initialize config={}
      super config
      @ant_home = Pathname.new(path).dirname.dirname
    end
    
    def configure src, build, install, build_type, options={}
      @src = src
    end
    
    def build build
      Platform.execute "#{path} -f build.xml", wd: @src
    end
    
    def install build
      
    end
    
  end
end
