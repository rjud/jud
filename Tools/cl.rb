require 'c'

class Cl < Jud::C::Compiler
  
  class << self
    
    attr_reader :vc_install_dir, :vs_install_dir
    attr_reader :vc_common_tools_dir, :windows_sdk_dir
    
    def load_path; false; end
    
    def variants; return [Platform::WIN32]; end
    
    def extra_configure config
      # Configure
      configure_directory config, 'VCInstallDir', lambda { get_vc_install_dir }
      configure_directory config, 'VSInstallDir', lambda { get_vs_install_dir }
      configure_directory config, 'VCCommonToolsDir', lambda { get_vs_common_tools_dir }
      configure_directory config, 'WindowsSdkDir', lambda { get_windows_sdk_dir }
      # Get the final configuration
      @vc_install_dir = get_directory config, 'VCInstallDir'
      @vs_install_dir = get_directory config, 'VSInstallDir'
      @vc_common_tools_dir = get_directory config, 'VCCommonToolsDir'
      @windows_sdk_dir = get_directory config, 'WindowsSdkDir'
      # Load environment
      # Microsoft Visual Studio
      path = @vs_install_dir.join('Common7', 'IDE').to_s
      # Microsoft Visual Studio Common Tools
      path << ';' << @vs_common_tools_dir.to_s
      # Microsoft Visual Compiler
      path << ';' << @vc_install_dir.join('BIN').to_s
      # We may add VCPackages to path
      ENV['INCLUDE'] = @vc_install_dir.join('INCLUDE').to_s
      ENV['LIB'] = @vc_install_dir.join('LIB').to_s
      ENV['LIBPATH'] = @vc_install_dir.join('LIB').to_s
      # Microsoft SDK
      path << ";" << @windows_sdk_dir.join('bin').to_s
      ENV['INCLUDE'] += ";" << @windows_sdk_dir.join('include').to_s
      ENV['LIB'] += ";" << @windows_sdk_dir.join('lib').to_s
      # Set new environment
      ENV['PATH'] = path << ";" << ENV['PATH']
    end  
    
    def get_vs_install_dir
      return Pathname.new reg_query('SOFTWARE\Microsoft\VisualStudio\SxS\VS7', version)
    end
    
    def get_vc_install_dir
      return Pathname.new reg_query('SOFTWARE\Microsoft\VisualStudio\SxS\VC7', version)
    end
    
  end
  
  def initialize(name, config = {})
    super(name)
  end
  
end
