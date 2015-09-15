class Context
  
  attr_accessor :prj, :name, :debug, :release, :src, :build, :prefix
  
  def initialize prj, build_type
    @prj = prj
    @name = prj.name
    @debug = build_type == :Debug
    @release = build_type == :Release
    @src = prj.srcdir build_type
    @build = prj.builddir build_type
    @prefix = prj.prefix
  end
  
  def debug?; @debug; end
  def release?; @release; end
  
  def cd dir
    Dir.chdir dir
  end
  
  def cp file, destination
    FileUtils.copy_file file, destination
  end
  
  def mkdir *dirs, **options
    dirs.each do |dir|
      FileUtils.mkdir_p dir, options unless Dir.exist? dir
    end
  end
  
  def make rule, **options
    prj.class.build_tool.execute rule, options
  end
  
  def pwd
    Dir.getwd
  end

  def run exe, *args
    cmd = exe.to_s
    args.each { |a| cmd += " #{a}" }
    Platform.execute cmd
  end
  
  def project sym
    Application::project sym
  end
  
end
