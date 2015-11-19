require 'scm_tool'

module Jud::Tools
  class Wget < SCMTool
    
    class << self
      def load_path; false; end
    end
    
    #
    # ==== Attributes
    #
    # * +url+ - URL of the file to download. It may be a format specification.
    #
    # ==== Options
    # * +:srcrename+ - After unpacking, name of the directory. It may be a format specification
    #
    def initialize url, options={}
      super url, options
    end
    
    def checkout src, prj, options = {}
      begin
        surl = @url % prj.options
      rescue KeyError => e
        puts (Platform.red "Can't resolve url #{@url}:\n  #{e}")
        abort
      end
      packtool, ext = 
        if surl.include? '.tar.gz' then
          [Tarball.new, '.tar.gz']
        elsif surl.include? '.zip' then
          [ZipTool.new, '.zip']
        else
          raise Error, "wget: unkown extension for URL #{surl}"
        end
      filename = prj.packsrcfile(ext).to_s
      tmpfile = Pathname.new(filename + '.tmp')
      tmpfile.delete if tmpfile.file?
      if not File.exists? filename then
        puts (Platform.blue "Downloading #{surl} to #{filename}...")
        if surl.start_with? 'http' then
          require 'mechanize'
          agent = Mechanize.new
          agent.set_proxy $general_config['proxy']['host'], $general_config['proxy']['port'].to_i if Platform.use_proxy? surl
          agent.pluggable_parser.default = Mechanize::Download
          # no-check-certificate
          begin
            agent.get(surl).save tmpfile.to_s
          rescue SocketError => e
            puts (Platform.red "I can't download #{surl} over HTTP\n#{e}")
          end
        elsif surl.start_with? 'ftp' then
          require 'uri'
          require 'net/ftp'
          uri = URI.parse surl
          ftp = Net::FTP.new(uri.host, 'anonymous', '')
          ftp.chdir(File.dirname uri.path)
          ftp.getbinaryfile( (File.basename uri.path), tmpfile.to_s, 1024)
          ftp.close
        else
          puts (Platform.red "[wget] Unknown protocol for URL #{surl}")
          abort
        end
      end
      tmpfile.rename filename unless File.exists? filename
      packtool.unpack filename, $src
      FileUtils.mv ($src.join (@options[:srcrename] % prj.options) ), src.to_s if @options[:srcrename]
    end
    
    def update src
      
    end
    
    def branch src, branch
      
    end
    
    def tag src, tag
      
    end
    
    def tags src
      
    end
    
  end
end
