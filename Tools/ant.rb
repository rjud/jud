require 'build_tool'

module Jud
  module Tools
    class Ant < BuildTool

      class << self
        def name; 'Ant'; end
        
        def extra_configure config
        end
      end
      
      Ant.configure
      
      attr_reader :ant_home
      
      def initialize
        super()
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
end
