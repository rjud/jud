require 'fileutils'
require 'open3'
require 'uri'

case RbConfig::CONFIG['host_os']
when /mswin|mingw/
  require 'win32ole'
end

class Platform
  
  class Error < RuntimeError; end
  
  UNIX  = 1 << 1
  WIN32 = 1 << 2
    
  def self.colorize text, color_code
    "#{color_code}#{text}\033[0m"
  end
  
  def self.red text; colorize text, "\033[31m"; end
  def self.green text; colorize text, "\033[32m"; end
  def self.yellow text; colorize text, "\033[33m"; end
  def self.blue text; colorize text, "\033[36m"; end
  def self.pink text; colorize text, "\033[35m"; end
  def self.cyan text; colorize text, "\033[36m"; end
  def self.gray text; colorize text, "\033[37m"; end
  
  def self.putfinds name, value
    dots = "." * (15 - name.size < 0 ? 0 : 15 - name.size)
    puts (Platform.green "Found #{name}#{dots}#{value}")
  end
  
  def self.create repository, name
    repo_config = Jud::Config.instance.get_repo_config repository
    prefix = Pathname.new repo_config['dir']
    config = Jud::Config.instance.config['platforms']
    if config.include? name then
      puts (Platform.red "Already existing platform #{name}")
    end
    config = Jud::Config.instance.config['platforms'][name]
    config['repository'] = repository
    config['home'] = default_home prefix
    config['src'] = default_src prefix
    config['build'] = default_build prefix, name
    config['install'] = default_install prefix, name
    config['packages'] = default_packages prefix
    config['trash'] = default_trash prefix
    if Platform.is_windows? then
      config['CMake Generator'] = 'NMake Makefiles'
      #config['CMake Native Build Tool'] = ''
    else
      config['CMake Generator'] = 'Unix Makefiles'
      #config['CMake Native Build Tool'] = ''
    end
    config['arch'] = 'x86'
  end
  
  def self.default_home prefix; prefix.join('home').to_s; end
  def self.default_src prefix; prefix.join('src').to_s; end
  def self.default_build prefix, name; prefix.join("build-#{name}").to_s; end
  def self.default_install prefix, name; prefix.join("install-#{name}").to_s; end
  def self.default_packages prefix; prefix.join('packages').to_s; end
  def self.default_trash prefix; prefix.join("trash").to_s; end
  
  attr_reader :name#, :language_to_composite
  
  def initialize name
    @name = name
    @config = Jud::Config.instance.get_platform_config name
    @tool_configs = {}
    @language_to_compiler = {}
    @repo_config = Jud::Config.instance.get_repo_config @config['repository']
    #@language_to_composite = {}
    prefix = Pathname.new @repo_config['dir']
    $home = path_from_config 'home', (Platform.default_home prefix)
    $src = path_from_config 'src', (Platform.default_src prefix)
    $build = path_from_config 'build', (Platform.default_build prefix, name)
    $install = path_from_config 'install', (Platform.default_install prefix, name)
    $packdir = path_from_config 'packages', (Platform.default_packages prefix)
    $trash = path_from_config 'trash', (Platform.default_trash prefix)
    load_tool_configs
  end
  
  def load_tool_configs
    $tools_config.each do |name, config|
      instanceof = config['instanceof']
      if @tool_configs.key? instanceof
        @tool_configs[instanceof] << [name, config]
      else
        @tool_configs[instanceof] = [[name, config]]
      end
    end
  end
  
  def path_from_config var, default
    if @config.has_key? var
      Pathname.new @config[var]
    else
      @config[var] = default
      Pathname.new default
    end
  end
  
  #def setup composite
  #  begin
  #    load $juddir.join("Platforms", "#{composite.downcase}.rb")
  #    klass = Object.const_get(composite)
  #    klass.create @config
  #    @config['composites'] << klass.name
  #  rescue LoadError
  #    raise Error, "Can't load platform #{composite}"
  #  end
  #end
  
  #def load_composites
  #  @config['composites'].each do |composite|
  #    load_composite composite
  #  end
  #end
  
  #def load_composite name
  #  begin
  #    load $juddir.join("Platforms", "#{name.downcase}.rb")
  #    #load "Platforms/#{name.downcase}.rb"
  #    composite = Object.const_get(name).new name
  #    composite.class.languages.each do |language|
  #      if language_to_composite.has_key? language then
  #        raise Error, "There is already a platform for the language #{language.name}"
  #      else
  #        language_to_composite[language] = composite
  #      end
  #    end
  #  rescue LoadError => e
  #    raise Error, "Can't load platform #{name}\n  #{e.backtrace}"
  #  end
  #end
  
  #def get_composite_for_language language
  #  if language_to_composite.has_key? language then
  #    language_to_composite[language]
  #  else
  #    raise Error, "Can't find a platform for the language #{language.name}"
  #  end
  #end
  
  def cmake_native_build_tool
    toolname = @config['CMake Native Build Tool']
    #classname = $tools_config[toolname]['instanceof']
    tool = get_tool toolname #classname
    tool
  end
  
  def get_compiler language
    
    configs = []
    found_compiler = nil
    
    return @language_to_compiler[language] if @language_to_compiler.key? language
    
    @tool_configs.each do |toolclass, tools|
      tools.each do |tool|
        name, config = tool[0], tool[1]
        instanceof = config['instanceof']
        load ($juddir + 'Tools' + "#{instanceof.downcase}.rb").to_s
        toolclass = Object.const_get "Jud::Tools::#{instanceof}"
        configs << [toolclass, name, config] if toolclass < language
      end
    end
    
    if configs.size == 0
      puts (Platform.red "Can't find compiler for language #{language}")
      abort
    elsif configs.size == 1
      compiler, name, config = configs[0][0], configs[0][1], configs[0][2]
      puts (Platform.green "Found compiler #{name} for language #{language}")
      found_compiler = compiler.new
    else
      configs.each do | value |
        compiler, name, config = value[0], value[1], value[2]
        if @config['tools'].include? name
          unless found_compiler.nil?
            puts (Platform.red "Found at least two compilers for language #{language}")
            abort
          end
          puts (Platform.green "Found compiler #{compiler} for language #{language}")
          found_compiler = compiler.new 
        end
      end
      if found_compiler.nil?
        puts (Platform.red "Too many compilers for language #{language}. Please, configure your platform.")
        abort
      end
    end
    
    @language_to_compiler[language] = found_compiler
    
  end
  
  def get_tool name
    classname = $tools_config[name]['instanceof']
    load ($juddir + 'Tools' + "#{classname.downcase}.rb").to_s
    return Object.const_get("Jud::Tools::#{classname}").new
  end
  
  def get_tool_config classname
    configs = @tool_configs[classname]
    if configs.nil?
      toolclass = Object.const_get("Jud::Tools::#{classname}")
      if toolclass.pure_ruby
        $tools_config[classname]['instanceof'] = classname
        return [ classname, $tools_config[classname] ]
      else
        raise Error, "Can't find tool #{classname}"
      end
    elsif configs.size == 1
        return configs[0]
    else
      configs.each do | value |
        name, config = value[0], value[1]
        return value if @config['tools'].include? name
      end
      puts (Platform.red "Too many tools for #{classname}. Please, configure your platform.")
      abort
    end
  end
  
  def self.use_proxy? url
    return false if $general_config['proxy']['host'].empty?
    uri = URI.parse url
    uri.host
    $general_config['proxy']['exceptions'].each do |exception|
      return false if uri.host.end_with? exception
    end
    return true
  end
  
  def self.proxy_url
    host = $general_config['proxy']['host']
    port = $general_config['proxy']['port']
    return "http://#{host}:#{port}"
  end

  def self.set_env_proxy
    @oldproxy = ENV['http_proxy']
    @oldproxys = ENV['https_proxy']
    ENV['http_proxy'] = "#{$general_config['proxy']['host']}:#{$general_config['proxy']['port'].to_i}"
    ENV['https_proxy'] = ENV['http_proxy']
  end
  
  def self.unset_env_proxy
    ENV['http_proxy'] = @oldproxy
    ENV['https_proxy'] = @oldproxys
  end
  
  # wd, safe, keep
  def self.execute cmd, options = {}
    options = {safe: false}.merge(options)
    if options.key? :wd
      wd = options[:wd]
      FileUtils.mkdir_p wd.to_s if not wd.directory?
      Dir.chdir wd.to_s
      puts Platform.blue(wd.to_s + '> ' + cmd)
    else
      puts Platform.blue(Dir.getwd + '> ' + cmd)
    end
    exit_status = nil
    lines = []
    begin
      #mutex = Mutex.new
      #userinput = nil
      #Thread.new do
      #  while true do
      #    temp = $stdin.gets
      ##    mutex.synchronize do
       #     userinput = temp
      #    end
      #    sleep 0.1
      #  end
      #end
      Open3.popen2e cmd do |stdin, stdout_err, wait_thr|
        #$stdin.reopen stdin
        #while true do
          while line = stdout_err.gets
            puts line
            lines << line.chomp if options.key? :keep and line.match(/#{options[:keep]}/)
            #mutex.synchronize do
            #  unless userinput.nil?
            #    stdin.puts userinput
            #    userinput = nil
            #  end
            #end
            #if line =~ /Do you accept the terms of the license?/
            #  stdin.puts 'y'
            #end
            #sleep 0.1
          end
        #end
        exit_status = wait_thr.value
      end
    rescue Errno::ENOENT => e
      puts (Platform.red e)
      abort
    end
    if options[:safe] or exit_status.success? then
      [exit_status, lines]
    else
      raise Error, "Command #{cmd} failed"
    end
  end
  
  def self.find_executable exe, optional=false
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each do |ext|
        filename = File.join(path, "#{exe}#{ext}")
        return filename if File.executable? filename
      end
    end
    puts (Platform.red "Can't find #{exe}")
    if optional
      return nil
    else
      raise Error, "Can't find executable #{exe}"
    end
  end
  
  def self.find_executables exe
    executables = []
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each do |ext|
        filename = File.join path, "#{exe}#{ext}"
        executables << filename if File.executable? filename
      end
    end
    executables
  end
  
  def self.is_darwin?; RUBY_PLATFORM =~ /darwin/; end
  def self.is_windows?; RUBY_PLATFORM =~ /mswin|mingw/; end
  def self.is_linux?; RUBY_PLATFORM =~ /linux/; end
  
  def arch
    if @config.key? 'arch'
      @config['arch']
    else
      raise Error, 'Please, define the variable arch for your platform'
    end
  end
  
  def is_32?;
    self.arch =~ /x86/ or self.arch =~ /arm/
  end
  
  def is_64?;
    self.arch =~ /x64/ or self.arch =~ /arm64/
  end
  
  def build_name
    
    name = ''
    
    if Platform.is_windows? then
      name = 'win32'
    elsif Platform.is_linux? then
      name = 'linux'
    elsif Platform.is_darwin? then
      name = 'macosx'
    else
      raise Error, "Unknown OS"
    end
    
    name += "-#{self.arch}"
    
    name
    
  end
  
  def pack_tool
    if Platform.is_windows? then
      require 'Tools/tarball'
      Jud::Tools::Tarball.new
      #require 'Tools/ziptool'
      #ZipTool.new
    else
      require 'Tools/tarball'
      Jud::Tools::Tarball.new
    end
  end
  
  def memcheck_tool
    if Platform.is_linux? then
      require 'Tools/valgrind'
      Jud::Tools::Valgrind.new
    else
      nil
    end
  end
  
  def self.nbcores
    case RbConfig::CONFIG['host_os']
    when /darwin9/
      `hwprefs cpu_count`.to_i
    when /darwin/
      ((`which hwprefs` != '') ? `hwprefs thread_count` : `sysctl -n hw.ncpu`).to_i
    when /linux/
      `cat /proc/cpuinfo | grep processor | wc -l`.to_i
    when /freebsd/
      `sysctl -n hw.ncpu`.to_i
    when /mswin|mingw/
      wmi = WIN32OLE.connect("winmgmts://")
      cpu = wmi.ExecQuery("select NumberOfCores from Win32_Processor")
      # TODO count hyper-threaded in this
      cpu.to_enum.first.NumberOfCores
    end
  end
  
end
