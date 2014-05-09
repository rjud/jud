require 'build_tool'

module Jud
  module Tools
    class Ant < BuildTool

      class << self
        def name; 'Ant'; end
      end
      
      def extra_configure config
        puts config
      end
      
      Ant.configure
      
      def initialize
        super()
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
