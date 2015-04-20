require 'tool'

class PackTool < Tool
  
  attr_reader :ext
  
  def initialize ext
    super()
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
      ZipTool.new.unpack filename, destination
    when '.gz'
      Tarball.new('tar.gz').unpack filename, destination
    else
      tool.unpack filename, destination
    end
  end
  
end
