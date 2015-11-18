require 'java'
require 'compiler'

module Jud::Tools
  class JDK < Jud::Compiler
    
    include Jud::Languages::Java
    
    class << self
      
      def configure
        if Platform.is_windows?          
          [ "SOFTWARE", "SOFTWARE\\Wow6432Node" ].each do |registry|
            reg_name = registry + "\\JavaSoft\\Java Development Kit"
            Win32::Registry::HKEY_LOCAL_MACHINE.open(reg_name) do |reg|
              reg.each_key do |key, _|
                if key =~ /^\d+.\d+$/
                  home = Pathname.new reg_query (reg_name + "\\" + key), 'JavaHome'
                  path = home + 'bin' + 'java.exe'
                  tlname =
                    if RUBY_PLATFORM =~ /i386/ or registry == 'SOFTWARE'
                      "JDK #{key} (32)"
                    else
                      "JDK #{key} (64)"
                    end
                  save_config_property tlname, 'path', path
                  Platform.putfinds tlname, path
                end
              end
            end
          end
        else
          super
        end
      end
      
    end
    
    def initialize config={}
      super config
    end
    
    def setenv context
      context.appenv 'PATH', (Pathname.new @path).dirname
      context.setenv 'JAVA_HOME', (Pathname.new @path).dirname.dirname
    end
    
  end
end
