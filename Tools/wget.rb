require 'scm_tool'

class Wget < SCMTool
  
  class << self
    def load_path; false; end
  end
  
  attr_reader :packtool
  
  Wget.configure
    
  def initialize url, packtool, options={}
    super(url)
    @packtool = packtool
  end
  
  def checkout src, options = {}
    require 'mechanize'
    agent = Mechanize.new
    agent.set_proxy $general_config['proxy']['host'], $general_config['proxy']['port'].to_i if Platform.use_proxy? @url
    agent.pluggable_parser.default = Mechanize::Download
    filename = src.dirname.join('tmp.tar.gz')
    puts (Platform.blue "Download #{@url} to #{filename}")
    agent.get(@url).save filename
    @packtool.unpack filename, src.to_s    
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
