class Context
  
  EnvironmentVariable = Struct.new(:var, :value, :append)

  PATH_SEPARATOR = File::PATH_SEPARATOR
  
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
    @environments = []
    @old_environments = {}
  end
  
  def debug?; @debug; end
  def release?; @release; end
  def arch; $platform.arch; end
  def is_32?; $platform.is_32?; end
  def is_64?; $platform.is_64?; end
  
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
    setenv var, value
    ENV[var] = value.to_s
  end
  
  def run exe, *args
    cmd = exe.to_s
    args.each do |a|
      cmd += " #{a.to_s}"
    end
    Platform.execute cmd
  end
  
  def push
    @environments.each do |variable|
      if ENV[variable.var].nil? || (not variable.append)
        ENV[variable.var] = variable.value
      else
        next if variable.value.eql? '/bin'
        next if variable.value.eql? '/usr/bin'
        ENV[variable.var] = variable.value + File::PATH_SEPARATOR + ENV[variable.var]
      end
    end
  end
  
  def pop
    @old_environments.each do |var, value|
      if value.nil?
        ENV.delete var
      else
        ENV[var] = value
      end
    end
    @old_environments = {}
  end
  
  def setenv var, value, append=false
    unless @old_environments.key? var
      oldvalue = ENV[var]
      @old_environments[var] = oldvalue
      @environments << EnvironmentVariable.new(var, oldvalue, false) if append
    end
    @environments << EnvironmentVariable.new(var, value.to_s, append)
  end
  
  def appenv var, value
    setenv var, value, true
  end
  
  def project sym
    Application::project sym
  end
  
  def python *args
    cmd = ($platform.get_tool_by_classname 'Python').path
    puts (Platform.yellow "PYTHONPATH: #{ENV['PYTHONPATH']}")
    run cmd, *args
  end
  
  def perl *args
    cmd = ($platform.get_tool_by_classname 'Perl').path
    run cmd, *args
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
