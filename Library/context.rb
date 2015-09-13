class Context
  
  attr_accessor :project, :name, :debug, :release, :src, :build, :prefix
  
  def initialize project, build_type
    @project = project
    @name = project.name
    @debug = build_type == :Debug
    @release = build_type == :Release
    @src = project.srcdir build_type
    @build = project.builddir build_type
    @prefix = project.prefix
  end
  
  def debug?; @debug; end
  def release?; @release; end
  
  def cd dir
    Dir.chdir dir
  end
  
  def mkdir *dirs, **options
    dirs.each do |dir|
      FileUtils.mkdir_p dir, options unless Dir.exist? dir
    end
  end
  
  def make rule, **options
    @project.class.build_tool.execute rule, options
  end
  
  def pwd
    Dir.getwd
  end

  def run exe, *args
    cmd = exe.to_s
    args.each { |a| cmd += " #{a}" }
    Platform.execute cmd
  end
  
end
