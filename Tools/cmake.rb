require 'build_tool'
require 'open3'

module Jud
  module Tools
    class CMake < BuildTool
      
      class << self
        def name; 'CMake'; end        
        def extra_configure config
        end
      end
      
      CMake.configure
      
      attr_reader :native_build_tool
      
      def initialize config={}
        super()
        platform = $platform_config['Native Build Tool']
        @native_build_tool = $platform.get_tool platform
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
        ENV['PATH'] = Pathname.new(@native_build_tool.path).dirname.to_s << ';' << ENV['PATH']
        cmakecache = File.join(build, 'CMakeCache.txt').to_s
        File.delete cmakecache if File.exists? cmakecache
        cmd = '"' + path + '"'
        if $platform_config.include? 'CMake Generator' then
          cmd += ' -G "' + $platform_config['CMake Generator'] + '"' 
        end
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
        resolved_options = []
        #if $platform_config.include? 'CMake System Name' then
        #  cmd += ' -DCMAKE_SYSTEM_NAME=' + $platform_config['CMake System Name']
        #end
        resolved_options << ResolvedOption.new('CMAKE_INSTALL_PREFIX', :PATH, true, install.to_s, nil)
        resolved_options << ResolvedOption.new('CMAKE_DEBUG_POSTFIX', :STRING, build_type == :Debug, 'd', nil)
        resolved_options << ResolvedOption.new('CMAKE_BUILD_TYPE', :STRING, true, build_type.to_s, nil)
        resolved_options << ResolvedOption.new('CMAKE_CXX_FLAGS', :STRING, (Platform.is_linux? and Platform.is_64?), '-fPIC', nil)
        if prj.depends.size > 0 then
          value = '"'
          prj.depends.each do |d|
            p = prj.project(d.name.to_sym)
            value += p.prefix.to_s + ';'
            p.lookin.each { |lk| cmd += lk.to_s + ';' }
          end
          value += '"'
          resolved_options << ResolvedOption.new('CMAKE_PREFIX_PATH', :STRING, true, value, nil)
        end
        context = Context.new prj, build_type
        resolved_options += resolve_options(context, options)
        resolved_options        
      end
      
      def build *args
        @native_build_tool.build *args
      end
      
      def install *args
        if @native_build_tool.is_a? Ninja
          @native_build_tool.install *args
        else
          @native_build_tool.install *args, { :fast => true }
        end
      end
      
    end

  end
end
