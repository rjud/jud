require 'build_tool'

class AutoTools < BuildTool
    
  attr_reader :native_build_tool
  
  def initialize
    super()
    platform = $platform_config['Native Build Tool']
    @native_build_tool = $platform.get_tool platform
  end
  
  def option_to_s opt
    case opt.type
    when :BOOLEAN then opt.value ? 'yes' : 'no'
    else opt.value
    end
  end
  
  def configure src, build, install, build_type, prj, options={}
    configure = File.join(src, 'configure')
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
    resolve_options(context, options).each do |opt|
      if opt.name == 'CPPFLAGS'
        cmd += " #{opt.name}=\"#{option_to_s opt}"
        if Platform.is_linux? and Platform.is_64? then
          cmd += " -fPIC"
          fpicset = true
        end 
        cmd += "\""
      else
        cmd += " #{opt.name}=#{option_to_s opt}"
      end
    end
    if Platform.is_linux? and Platform.is_64? then
      cmd += " CPPFLAGS=-fPIC" unless fpicset
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
