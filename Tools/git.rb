require 'scm_tool'

module Jud::Tools
  class Git < SCMTool
    
    class << self
      
      def configure
        if Platform.is_windows?
          require 'win32_utilities'
          directory = Pathname.new reg_query 'SOFTWARE\TortoiseGit', 'Directory'
          ENV['PATH'] = (directory + 'bin').to_s + ";" + ENV['PATH']
        end
        super
      end
      
      def guess url; return url.end_with? '.git' end
      
    end
    
    def initialize url, options={}
      super url, options
    end
    
    # Optimize to clone once from the remote server and then use it as a local server.
    
    def checkout src, prj, options = {}
      
      cmd = "\"#{path}\" clone"
      cmd += " #{@options[:args]}" if @options.has_key? :args
      cmd += " #{@url} #{src.basename.to_s}"
      Platform.execute cmd, {:wd => src.dirname}.merge(options)
      
      cmd = nil
      if options.has_key? :tag then
        cmd = "\"#{path}\" checkout #{options[:tag]}"
        Platform.execute cmd, {:wd => src}.merge(options)
      elsif options.has_key? :branch then
        cmd = "\"#{path}\" checkout #{options[:branch]}"
        Platform.execute cmd, {:wd => src}.merge(options)
      elsif options.has_key? :version then
        cmd = "\"#{path}\" checkout #{tag_of_version options[:version]}"
      end
      
      Platform.execute cmd, {:wd => src}.merge(options) if not cmd.nil?
      
    end
    
    def tag_of_version version
      "v#{version}"
    end
    
    def get_revision src, options = {}
      cmd = "\"#{path}\" describe --always"
      exit_status = Platform.execute cmd, {:wd => src, :keep => '[0-9a-f]'}.merge(options)
      exit_status[1].last
    end
    
    def update src
      cmd = "\"#{path}\" pull"
      Platform.execute cmd, wd: src
    end
    
    def branch src, branch
      
    end
    
    def tag src, tag
      
    end
    
    def tags src
      cmd = '"' + path + '" tag'
      Platform.execute cmd, wd: src.dirname
    end
    
  end
end
