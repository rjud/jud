class Context
  
  attr_accessor :prj, :name, :debug, :release, :src, :build, :prefix
  attr_accessor :version, :major, :minor, :release, :nbcores
  
  def initialize prj, build_type
    @prj = prj
    @name = prj.name
    @debug = build_type == :Debug
    @release = build_type == :Release
    @src = prj.srcdir build_type
    @build = prj.builddir build_type
    @prefix = prj.prefix
    @version = prj.options[:version]
    @nbcores = Platform.nbcores
    if not @version.nil?
      ver = Jud::Version.new @version
      @major, @minor, @release = ver.major, ver.minor, ver.release
    end
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
  
  def mv file, destination
    FileUtils.move file, destination, :verbose => true
  end
  
  def make rule, **options
    prj.class.build_tool.execute rule, options
  end
  
  def pwd
    Dir.getwd
  end
  
  def export var, value
    ENV[var] = value.to_s
  end
  
  def run exe, *args
    cmd = exe.to_s
    args.each do |a|
      cmd += " #{a.to_s}"
    end
    Platform.execute cmd
  end
  
  def project sym
    Application::project sym
  end
  
  def python *args
    require 'python2'
    cmd = Python2.new.path
    puts (Platform.yellow "PYTHONPATH: #{ENV['PYTHONPATH']}")
    run cmd, args
  end
  
  def eval_option func
    case func
    when Proc
      return self.instance_eval &func
    when Hash
      raise Error, "Context.eval_option: in hash mode, only one element is admitted." if func.size != 1
      func.each do |prj, arg|
        case arg
        when Symbol
          return project(prj).send arg
        when Array
          return project(prj).send arg[0], *arg[1..-1]
        when Proc
          return arg.call project(prj)
        else
          raise Error, "Context.eval_option: in hash mode, evaluation not implemented for #{arg.class}."
        end
      end
    else
      return func
    end
  end
  
end
