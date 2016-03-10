require 'build_tool'
require 'open3'

module Jud::Tools
  class CMake < BuildTool

    class << self
      
      def configure
        if Platform.is_windows?
          ['SOFTWARE', 'SOFTWARE\Wow6432Node'].each do |registry|
            begin
              Win32::Registry::HKEY_LOCAL_MACHINE.open "#{registry}\\Kitware" do |reg|
                reg.each_key do |key, _|
                  default = Pathname.new reg_query "#{registry}\\Kitware\\#{key}", ''
                  path = default + 'bin' + 'cmake.exe'
                  save_config_property key, 'path', path
                  Platform.putfinds key, path
                end
              end
            rescue Win32::Registry::Error => e
              puts (Platform.red "Skip registry entry #{registry}\\Kitware")
            end
          end
        else
          super
        end
      end
      
    end
    
    attr_reader :arch, :native_build_tool, :generator
    
    def initialize wnodev=false, config={}
      
      super config
      
	  @wnodev = wnodev
      if $platform_config.include? 'CMake Generator'
        @generator = $platform_config['CMake Generator']
      elsif Platform.is_windows?
        @generator = "NMake Makefiles"
        $platform_config['CMake Generator'] = @generator
      else
        @generator = "Unix Makefiles"
        $platform_config['CMake Generator'] = @generator
      end
      
      unless @generator =~ /Visual Studio/
        if $platform_config.include? 'CMake Native Build Tool'
          @native_build_tool = $platform.get_tool_by_name $platform_config['CMake Native Build Tool']
        elsif @generator =~ /NMake Makefiles/
          @native_build_tool = $platform.get_tool_by_classname 'NMake'
          $platform_config['CMake Native Build Tool'] = Tool.toolname @native_build_tool.class
        elsif @generator =~ /Unix Makefiles/
          @native_build_tool = $platform.get_tool_by_classname 'Make'
          $platform_config['CMake Native Build Tool'] = Tool.toolname @native_build_tool.class
        end
      end
      
      unless $platform_config.include? 'arch'
        $platform_config['arch'] = 'x86'
      end
      
      @arch = $platform_config['arch']
      
    end
    
    def option_to_s opt
      case opt.type
      when :BOOLEAN
        opt.value ? 'ON' : 'OFF'
      when :PATH
        case opt.value
        when Pathname
          opt.value.to_s
        else
          opt.value
        end
      else opt.value
      end
    end
    
    # Remove all arguments but project and only use project
    def configure src, build, install, build_type, prj, options={}
      #if not @native_build_tool.nil?
      #  ENV['PATH'] = Pathname.new(@native_build_tool.path).dirname.to_s << ';' << ENV['PATH']
      #end
      cmakecache = File.join(build, 'CMakeCache.txt').to_s
      File.delete cmakecache if File.exists? cmakecache
      cmd = '"' + path + '"'
      cmd += ' -Wno-dev'
      cmd += ' -G "' + @generator + '"'
      get_options(src, build, install, build_type, prj, options).each do |opt|
        if opt.enabled
          final_value = option_to_s opt
          puts (Platform.yellow "#{opt.name}: #{final_value}")
          cmd += ' -D' + opt.name + '=' + final_value
        end
      end
      cmd += ' ' + src.to_s
      Platform.execute cmd, wd: build
    end
    
    def get_options src, build, install, build_type, prj, options={}
      resolved_options = {}
      #if $platform_config.include? 'CMake System Name' then
      #  cmd += ' -DCMAKE_SYSTEM_NAME=' + $platform_config['CMake System Name']
      #end
      resolved_options['CMAKE_INSTALL_PREFIX'] = ResolvedOption.new('CMAKE_INSTALL_PREFIX', :PATH, true, install.to_s, nil)
      resolved_options['CMAKE_DEBUG_POSTFIX'] = ResolvedOption.new('CMAKE_DEBUG_POSTFIX', :STRING, build_type == :Debug, 'd', nil)
      if not $platform_config.include? 'CMake Generator' or not $platform_config['CMake Generator'] =~ /Visual Studio/
        resolved_options['CMAKE_BUILD_TYPE'] = ResolvedOption.new('CMAKE_BUILD_TYPE', :STRING, true, build_type.to_s, nil)
      end
      resolved_options['CMAKE_CXX_FLAGS'] = ResolvedOption.new('CMAKE_CXX_FLAGS', :STRING, (Platform.is_linux? and (arch == 'x86_64' or arch == 'x64') ), '-fPIC', nil)
      if prj.depends.size > 0 then
        value = '"'
        prj.depends.each do |d|
          p = prj.project(d.name.to_sym)
          value += p.prefix.to_s + ';'
          p.lookin.each { |lk| cmd += lk.to_s + ';' }
        end
        value += '"'
        resolved_options['CMAKE_PREFIX_PATH'] = ResolvedOption.new('CMAKE_PREFIX_PATH', :STRING, true, value, nil)
      end
      context = Context.new prj, build_type
      resolved_options.merge! (resolve_options context, options)
      resolved_options.values
    end
    
    def build build, build_type, options={}
      require 'Tools/make'
      if @native_build_tool.class <= Jud::Tools::Make
        @native_build_tool.build build, build_type, options
      else
        cmd = "\"#{path}\" --build #{build} --config #{build_type} --target ALL_BUILD"
        Platform.execute cmd
      end
    end
    
    def install build, build_type, options={}
      require 'Tools/ninja'
      if @native_build_tool.nil?
        cmd = "\"#{path}\" --build #{build} --config #{build_type} --target INSTALL"
        Platform.execute cmd
      elsif @native_build_tool.class < Jud::Tools::Ninja
        @native_build_tool.install build, build_type, options
      else
        @native_build_tool.install build, build_type, ({ :fast => true }.merge options)
      end
    end
    
  end
  
end
