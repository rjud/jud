class CMake < Project
  
  cxx
  wget 'http://www.cmake.org/files/v3.2/cmake-3.2.2.tar.gz', (Tarball.new '.gz'), { :srcrename => 'cmake-3.2.2' }
  autotools
  
  configure do
    run "#{src}/bootstrap --prefix=#{prefix}"
  end
  
  def build_types; [:Release]; end  
  def bin_dir; prefix.join('bin').to_s; end
  
end
