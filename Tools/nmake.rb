require 'make'
require 'cl'

class NMake < Make
  
  class << self
    def autoconfigurable; return true; end
    def autoconfigure
      version, tmp = Cl.autoconfigure2
      if version then
        cl = Cl.new version
        ENV['PATH'] += ";" << cl.get_vc_install_dir.join('BIN').to_s
        autoconfigure_executable name
      end
    end
  end
  
  def initialize name, options = {}
    super(name)
  end
  
end
