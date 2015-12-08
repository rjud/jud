require 'build_tool'

module Jud::Tools
  class Ant < BuildTool
    
    class << self

      def configure
        if Platform.is_windows?
          # Only keep ant.bat
          old_pathext = ENV['PATHEXT']
          ENV['PATHEXT'] = '.BAT'
          super
          ENV['PATHEXT'] = old_pathext
        else
          super
        end
      end
      
    end
    
    attr_reader :ant_home
    
    def initialize config={}
      super config
      @ant_home = Pathname.new(path).dirname.dirname
    end
    
    def configure src, build, install, build_type, prj, options={}
      @src = src
    end
    
    def build *args
      Platform.execute "#{path} -f build.xml", wd: @src
    end
    
    def install *args
      
    end
    
  end
end
