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
    agent.set_proxy 'proxy.onecert.fr', 80
    agent.pluggable_parser.default = Mechanize::Download
    filename = src.dirname.join('tmp.tar.gz')
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
