require 'make'
require 'cl'

module Jud
  module Tools
    class Ninja < Make

      class << self
        def name; 'Ninja'; end
        def extra_configure config; end
      end
      
      Ninja.configure
      
      def initialize options = {}
        super()
      end

      #def build_command_line options
        #cmd = '"' + path + '"'
        #mono = (options.has_key? :mono) and options[:mono]
        #cmd += ' -j3' if Platform.is_linux? and not mono
        #cmd += " -f #{options[:makefile]}" if options.has_key? :makefile
        #cmd += " -t msvc"
        #cmd += " #{options[:args]}" if options.has_key? :args
        #cmd += " #{options[:target]}" if options.has_key? :target
        #cmd += " -- cl.exe /nologo /showIncludes"
        #cmd += " -v"
        #cmd
      #end
      
    end
  end
end
