require 'build_tool'

module Jud::Tools
  class Make < BuildTool
    
    def initialize options={}
      super options
    end
    
    def build_command_line options
      cmd = '"' + path + '"'
      mono = (options.has_key? :mono) and options[:mono]
      cmd += " -j#{Platform.nbcores+1}" if Platform.is_linux? and not mono
      cmd += " -f #{options[:makefile]}" if options.has_key? :makefile
      cmd += " #{options[:args]}" if options.has_key? :args
      cmd += " #{options[:target]}" if options.has_key? :target
      cmd
    end
    
    def execute rule, options
      cmd = build_command_line (if rule.nil? then options else options.merge({ :target => rule }) end)
      Platform.execute cmd, options
    end
    
    def configure src, build, install, build_type, prj, options={}
    end
    
    def build builddir, options = {}
      execute nil, options.merge({ :wd => builddir })
    end
    
    def install builddir, options = {}
      fast = (options.has_key? :fast) and options[:fast]
      rule = 'install' + (fast ? '/fast' : '')
      execute rule, options.merge({ :wd => builddir })
    end
    
  end
end
