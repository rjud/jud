require 'tool'

class PackTool < Tool

  class << self
    def get_config; {}; end
  end
  
  attr_reader :ext
  
  def initialize ext, config
    super config
    @ext = ext
  end
  
  def pack filename, directory
    FileUtils.mkdir_p filename.dirname.to_s
    filename.delete if filename.file?
    pack_impl filename, directory
  end
  
  def self.unpack tool, filename, destination
    case filename.extname
    when '.zip'
      Jud::Tools::ZipTool.new.unpack filename, destination
    when '.gz'
      Jud::Tools::Tarball.new('tar.gz').unpack filename, destination
    else
      tool.unpack filename, destination
    end
  end
  
end
