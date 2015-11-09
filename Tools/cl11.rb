require 'cl'

module Jud::Tools
  class Cl11 < Cl
    
    class << self
      
      def configure
        # Nothing to configure. Everything is done by the class Cl.
      end
      
      def initialize_from_registry toolname, registry, version, arch
        super toolname, registry, version, arch
        # Windows SDK
        reg_name = 'SOFTWARE\Microsoft\Microsoft SDKs\Windows\v8.0'
        windows_sdk_dir = reg_query reg_name, 'InstallationFolder'
        save_config_property toolname, 'WindowsSdkDir', windows_sdk_dir
      end
      
    end
    
    def initialize config={}
      super config
    end
    
  end
end
