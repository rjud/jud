require 'scm_tool'

class Wget < SCMTool
  
  class << self
    def load_path; false; end
  end
  
  attr_reader :packtool
  
  def initialize url, packtool, options={}
    super(url)
    @packtool = packtool
    @options = options
  end
  
  def checkout src, options = {}
    filename = src.dirname.join('tmp.tar.gz')
    if url.start_with? 'http' then
      require 'mechanize'
      agent = Mechanize.new
      agent.set_proxy $general_config['proxy']['host'], $general_config['proxy']['port'].to_i if Platform.use_proxy? @url
      agent.pluggable_parser.default = Mechanize::Download
      puts (Platform.blue "Download #{@url} to #{filename}")
      agent.get(@url).save filename
    elsif url.start_with? 'ftp' then
      require 'uri'
      require 'net/ftp'
      uri = URI.parse url
      ftp = Net::FTP.new(uri.host, 'anonymous', '')
      ftp.chdir(File.dirname uri.path)
      ftp.getbinaryfile( (File.basename uri.path), filename, 1024)
      ftp.close    
    else
      puts (Platform.red "[wget] Unknown protocol for URL #{url}")
      abort
    end
    @packtool.unpack filename, $src
    FileUtils.mv ($src.join @options[:srcrename]), src.to_s if @options[:srcrename]
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
