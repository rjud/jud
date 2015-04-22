class CMake < Project
  
  cxx
  wget 'http://www.cmake.org/files/v3.2/cmake-3.2.2.tar.gz', (Tarball.new '.gz')
  autotools
  
  def configure_this src, build, install, build_type, options={}
    bootstrap = File.join(src, 'bootstrap')
    Platform.execute "#{bootstrap}", wd: build
  end
  
  def build_types; [:Release]; end

  def bin_dir; prefix.join('bin').to_s; end
  
end
