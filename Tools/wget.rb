require 'scm_tool'

module Jud::Tools
  class Wget < SCMTool
    
    class << self
      def pure_ruby; true; end      
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
      if Platform.is_windows?
        @cert = File.expand_path "~/.jud/cacert.pem"
        download_http 'http://curl.haxx.se/ca/cacert.pem', @cert.to_s unless File.exist? @cert          
      end
    end
    
    def download_http url, filename
      require 'mechanize'
      agent = Mechanize.new
      agent.set_proxy $general_config['proxy']['host'], $general_config['proxy']['port'].to_i if Platform.use_proxy? url
      agent.pluggable_parser.default = Mechanize::Download
      #agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      agent.agent.http.ca_file = @cert if Platform.is_windows?
      begin
        agent.get(url).save filename
      rescue SocketError => e
        puts (Platform.red "I can't download #{url} over HTTP\n#{e}")
      end
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
          require 'Tools/tarball'
          [Jud::Tools::Tarball.new, '.tar.gz']
        elsif surl.include? '.zip' then
          require 'Tools/ziptool'
          [Jud::Tools::ZipTool.new, '.zip']
        else
          raise Error, "wget: unkown extension for URL #{surl}"
        end
      filename = prj.packsrcfile(ext).to_s
      tmpfile = Pathname.new(filename + '.tmp')
      tmpfile.delete if tmpfile.file?
      if not File.exists? filename then
        puts (Platform.blue "Downloading #{surl} to #{filename}...")
        if surl.start_with? 'http' then
          download_http surl, tmpfile.to_s
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
