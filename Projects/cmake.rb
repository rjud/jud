class CMake < Project
  
  cxx
  wget 'http://www.cmake.org/files/v3.2/cmake-3.2.2.tar.gz', { :srcrename => 'cmake-3.2.2' }
  
  if Platform.is_windows?
  else
    autotools
  end
  
  configure do
    run "#{src}/bootstrap --prefix=#{prefix}"
  end
  
  def build_types; [:Release]; end  
  def bin_dir; prefix.join('bin').to_s; end
  
end
