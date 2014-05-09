class Ant < Project
  
  svn 'http://svn.apache.org/repos/asf/ant/core'
  
  def build_types; [:Release]; end
  
  def build_this bt
    if Platform.is_windows? then
      raise Error, "Not implemented"
    else
      #Platform.execute "./bootstrap.sh", :wd => (srcdir bt)
      #Platform.execute "./build.sh", :wd => (srcdir bt)
    end
  end
  
  def install_this bt
    src = (srcdir bt).join 'dist'
    FileUtils.mkdir_p prefix unless prefix.directory?
    FileUtils.cp_r (src.join 'bin'), prefix, :verbose => true
    FileUtils.cp_r (src.join 'lib'), prefix, :verbose => true
  end
  
end
