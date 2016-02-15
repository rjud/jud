class CMake < Project
  
  cxx
  wget 'http://www.cmake.org/files/v%{major}.%{minor}/cmake-%{version}.tar.gz', { :srcrename => 'cmake-3.2.2' }
  
  unless Platform.is_windows?
    autotools
  end
  
  configure do
    run "#{src}/bootstrap --prefix=#{prefix}"
  end
  
  def build_types; [:Release]; end  
  def bin_dir; prefix.join('bin').to_s; end
  
end
