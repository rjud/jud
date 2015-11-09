require 'make'
require 'cl'

module Jud::Tools
  class Ninja < Make
    
    def initialize options={}
      super options
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
