require 'scm_tool'

class Wget < SCMTool
  
  class << self
    def load_path; false; end
  end
  
  attr_reader :packtool

  #
  # ==== Attributes
  #
  # * +url+ - URL of the file to download. It may be a format specification.
  # * +packtool+ - Tool to unpack the file to download
  #
  # ==== Options
  # * +:srcrename+ - After unpacking, name of the directory. It may be a format specification
  #
  def initialize url, packtool, options={}
    super(url)
    @packtool = packtool
    @options = options
  end
  
  def checkout src, prj, options = {}
    surl = url % prj.options
    ext = 
      if surl.include? '.tar.gz' then
        '.tar.gz'
      elsif surl.include? '.zip' then
        '.zip'
      else
        raise Error, "wget: unkown extension for URL #{surl}"
      end
    filename = prj.packsrcfile(ext).to_s
    tmpfile = Pathname.new(filename + '.tmp')
    tmpfile.delete if tmpfile.file?
    if not File.exists? filename then
      puts (Platform.blue "Downloading #{url} to #{filename}...")
      if surl.start_with? 'http' then
        require 'mechanize'
        agent = Mechanize.new
        agent.set_proxy $general_config['proxy']['host'], $general_config['proxy']['port'].to_i if Platform.use_proxy? surl
        agent.pluggable_parser.default = Mechanize::Download
        puts (Platform.blue "Download #{surl} to #{filename}")
        # no-check-certificate
        agent.get(surl).save tmpfile.to_s
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
    @packtool.unpack filename, $src
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
