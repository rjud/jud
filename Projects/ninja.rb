class Ninja < Project
  
  git 'https://github.com/martine/ninja.git'
  insource
  
  def build_types; [:Release]; end
  
  build do
    python 'configure.py', '--bootstrap'
  end
  
  install do
    mkdir prefix + 'bin'
    cp 'ninja.exe', prefix + 'bin' + 'ninja.exe'
  end
  
end
