class Ant < Project
  
  svn 'http://svn.apache.org/repos/asf/ant/core'
  
  def build_types; [:Release]; end
  
  def build_this bt
    old_classpath = ENV['CLASSPATH']
    ENV.delete 'CLASSPATH'
    if Platform.is_windows? then
	  src = (srcdir bt).join 'dist'
	  FileUtils.mkdir_p src.join 'dist'
	  #Platform.execute "bootstrap.bat", :wd => (srcdir bt)
	  Platform.execute "build.bat", :wd => (srcdir bt)
    else
      Platform.execute "./bootstrap.sh", :wd => (srcdir bt)
      Platform.execute "./build.sh", :wd => (srcdir bt)
    end
    ENV['CLASSPATH'] = old_classpath
  end
  
  def install_this bt
    src = (srcdir bt).join 'dist'
    FileUtils.mkdir_p prefix unless prefix.directory?
    FileUtils.cp_r (src.join 'bin'), prefix, :verbose => true
    FileUtils.cp_r (src.join 'lib'), prefix, :verbose => true
  end
  
end
