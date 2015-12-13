require 'scm_tool'

module Jud::Tools
  class SVN < SCMTool
    
    class << self

      def configure
        if Platform.is_windows?
          require 'win32_utilities'
          directory = Pathname.new reg_query 'SOFTWARE\TortoiseSVN', 'Directory'
          ENV['PATH'] = (directory + 'bin').to_s + ";" + ENV['PATH']
        end
        super
      end

    end
    
    def initialize url=nil, options={}
      super url, options
    end
    
    def resolve_url options={}
      url = 
        if options.has_key? :trunk then
          @url + '/trunk/'
        elsif options.has_key? :branch then
          @url + '/branches/' + options[:branch]
        elsif options.has_key? :tag then
          @url + '/tags/' + options[:tag]
        elsif options.has_key? :version then
          url_of_version options[:version]
        else
          @url + '/trunk/'
        end
    end
    
    def url_of_version version
      @url + '/tags/' + version
    end
    
    def checkout src, prj=nil, options = {}
      url = resolve_url options
      cmd = "\"#{path}\" checkout"
      cmd += " --trust-server-cert" if (@options.has_key? :trustServerCert and @options[:trustServerCert])
      cmd += " --non-interactive"
      cmd += " #{@options[:args]}" if @options.has_key? :args
      cmd += " -r #{options[:rev]}" if options.has_key? :rev
      cmd += " #{url} #{src.basename.to_s}"
      Platform.execute cmd, {:wd => src.dirname}.merge(options)
    end
    
    def get_revision src, options = {}
      dir = File.dirname path
      bin = File.join(dir, if Platform.is_windows? then 'svnversion.exe' else 'svnversion' end)
      cmd = "\"#{bin}\""
      exit_status = Platform.execute cmd, {:wd => src, :keep => '[0-9a-z]'}.merge(options)
      exit_status[1].last
    end
    
    def update src
      cmd = '"' + path + '"'
      cmd += ' update'
      Platform.execute cmd, wd: src
    end
    
    def branch src, branch
      copy src, '/branches/' + branch
    end
    
    def tag src, tag
      copy src, '/tags/' + tag
    end
    
    def tags src
      cmd = '"' + path + '"'
      cmd += ' ls ' + @url + '/tags'
      Platform.execute cmd, wd: src.dirname
    end
    
    def copy src, dest
      cmd = '"' + path + '"'
      cmd += ' copy'
      cmd += ' -m "Create ' + dest + '"'
      cmd += ' ' + src.to_s
      cmd += ' ' + @url + dest
      Platform.execute cmd
    end
    
  end
end
