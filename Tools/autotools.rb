require 'build_tool'

module Jud::Tools
  class AutoTools < BuildTool
    
    class << self
      # It is not really pure ruby but autotools scripts are often provided with project sources.
      def pure_ruby; true; end
    end
    
    attr_reader :native_build_tool
    
    def initialize config={}
      super config
      @native_build_tool = $platform.get_tool 'Make'
    end
    
    def option_to_s opt
      case opt.type
      when :BOOLEAN then opt.value ? 'yes' : 'no'
      else opt.value
      end
    end
    
    def configure src, build, install, build_type, prj, options={}
      configure = File.join(src, 'configure')
      File.chmod(0744, configure)
      unless File.exists? configure then
        Platform.execute "aclocal -I config", wd: src
        Platform.execute "libtoolize --force", wd: src
        Platform.execute "autoheader", wd: src
        Platform.execute "automake --add-missing", wd: src
        Platform.execute "autoconf", wd: src
      end
      configlog = build.join 'config.log'
      FileUtils.rm configlog if File.exists? configlog
      cmd = "#{configure}"
      cmd += " --prefix=#{install.to_s}"
      fpicset = false
      context = Context.new(prj, build_type)
      resolve_options(context, options).each do |name, opt|
        if opt.name == 'CPPFLAGS' or opt.name == 'CFLAGS'
          cmd += " #{opt.name}=\"#{option_to_s opt}"
          if Platform.is_linux? and $platform_config['arch'] == 'x64'
            cmd += " -fPIC"
            fpicset = true
          end 
          cmd += "\""
        else
          if opt.value.size > 0
            cmd += " #{opt.name}=#{option_to_s opt}"
          else
            cmd += " #{opt.name}"
          end
        end
      end
      if Platform.is_linux? and $platform_config['arch'] == 'x64'
        cmd += " CPPFLAGS=-fPIC" unless fpicset
        cmd += " CFLAGS=-fPIC" unless fpicset
      end
      Platform.execute cmd, wd: build
    end
    
    def execute *args, **options
      @native_build_tool.execute *args, **options
    end
    
    def build *args
      @native_build_tool.build *args
    end
    
    def install *args
      @native_build_tool.install *args
    end
    
  end
end
