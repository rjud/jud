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
        cmakecache = File.join(build, 'CMakeCache.txt').to_s
        File.delete cmakecache if File.exists? cmakecache
        cmd = '"' + path + '"'
        if $platform_config.include? 'CMake Generator' then
          cmd += ' -G "' + $platform_config['CMake Generator'] + '"' 
        end
        cmd += ' -DCMAKE_INSTALL_PREFIX=' + install.to_s
        cmd += ' -DCMAKE_BUILD_TYPE=' + build_type.to_s
        if Platform.is_linux? and Platform.is_64? then
          cmd += ' -DCMAKE_CXX_FLAGS=-fPIC'
        end
        # Set dependencies
        cmd += ' -DCMAKE_PREFIX_PATH='
        prj.depends.each do |d|
          p = prj.project(d.name.to_sym)
          cmd += p.prefix.to_s + ';'
          p.lookin.each { |lk| cmd += lk.to_s + ';' }
        end
        resolve_options(options).each do |opt|
          cmd += ' -D' + opt.name + '=' + (option_to_s opt)
        end
        cmd += ' ' + src.to_s
        Platform.execute cmd, wd: build
      end
      
      def build *args
        @native_build_tool.build *args
      end
      
      def install *args
        @native_build_tool.install *args, { :fast => true }
      end
      
    end

  end
end
