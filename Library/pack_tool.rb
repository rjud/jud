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
  
end
