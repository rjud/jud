require 'fileutils'
require 'open3'

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
  def self.blue text; colorize text, "\033[34m"; end
  def self.pink text; colorize text, "\033[35m"; end
  def self.cyan text; colorize text, "\033[36m"; end
  def self.gray text; colorize text, "\033[37m"; end
  
  def self.create repository, name
    repo_config = Jud::Config.instance.get_repo_config repository
    prefix = Pathname.new repo_config['dir']
    config = Jud::Config.instance.config['platforms']
    if config.include? name then
      puts (Platform.red "Already existing platform #{name}")
    end
    config = Jud::Config.instance.config['platforms'][name]
    config['repository'] = repository
    config['src'] = prefix.join("src").to_s
    config['build'] = prefix.join("build-#{name}").to_s
    config['install'] = prefix.join("install-#{name}").to_s
    config['packages'] = prefix.join("packages").to_s
    config['composites'] = []
  end
  
  attr_reader :name, :language_to_composite
  
  def initialize name
    @name = name
    @config = Jud::Config.instance.get_platform_config name
    @repo_config = Jud::Config.instance.get_repo_config @config['repository']
    @language_to_composite = {}
    $home = Pathname.new(@repo_config['home'])
    $src = Pathname.new(@config['src'])
    $build = Pathname.new(@config['build'])
    $install = Pathname.new(@config['install'])
    $packdir = Pathname.new(@config['packages'])
  end
  
  def setup composite
    begin
      load $juddir.join("Platforms", "#{composite.downcase}.rb")
      klass = Object.const_get(composite)
      klass.create @config
      @config['composites'] << klass.name
    rescue LoadError
      raise Error, "Can't load platform #{composite}"
    end
  end
  
  def load_composites
    @config['composites'].each do |composite|
      load_composite composite
    end
  end
  
  def load_composite name
    begin
      load $juddir.join("Platforms", "#{name.downcase}.rb")
      composite = Object.const_get(name).new name
      composite.class.languages.each do |language|
        if language_to_composite.has_key? language then
          raise Error, "There is already a platform for the language #{language.name}"
        else
          language_to_composite[language] = composite
        end
      end
    rescue LoadError
      raise Error, "Can't load platform #{composite}"
    end
  end
  
  def get_composite_for_language language
    if language_to_composite.has_key? language then
      language_to_composite[language]
    else
      raise Error, "Can't find a platform for the language #{language.name}"
    end
  end
  
  def cmake_native_build_tool
    tool = @config['Native Build Tool']
    Object.const_get(tool).new(tool)
  end
  
  #def get_compiler language
  #  compiler_typenames = subsubclasses(language.class.compiler).collect{ |compiler| compiler.name }
  #  config = @config['tools'].each_key do |name|
  #    if compiler_typenames.include? name then
  #      tool = Object.const_get(name).new(name)
  #      puts (Platform.green "Found compiler #{tool.name} for language #{language.class.name}")
  #      return tool
  #    end
  #  end
  #  puts (Platform.red "Can't find compiler for language #{language.class.name}")
  #end
  
  def load_tool name
    load $juddir.join('Tools', name.downcase + '.rb').to_s
  end
  
  def get_tool name
    load $juddir.join('Tools', name.downcase + '.rb').to_s
    tool = Object.const_get(name).new(name)
    #config = Jud::Config.instance.config['tools']
    return tool
  end
  
  def load_tools
    @config['tools'].each_key do |name|
      load_tool name
    end
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
      puts Platform.blue(cmd)
    end
    exit_status = nil
    lines = []
    Open3.popen2e cmd do |stdin, stdout_err, wait_thr|
      while line = stdout_err.gets
        puts line
        lines << line.chomp if options.key? :keep and line.match(/#{options[:keep]}/)
      end
      exit_status = wait_thr.value
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
  
  def self.is_darwin?; RUBY_PLATFORM =~ /darwin/; end
  def self.is_windows?; RUBY_PLATFORM =~ /mswin|mingw/; end
  def self.is_linux?; RUBY_PLATFORM =~ /linux/; end
  
  def self.is_32?; RUBY_PLATFORM =~ /i386/; end
  def self.is_64?; RUBY_PLATFORM =~ /x86_64/; end
  
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
    
    if Platform.is_32? then
      name += '-x86'
    elsif Platform.is_64? then
      name += '-x86_64'
    else
      raise Error, "Unknown bits"
    end
    
    name
    
  end
  
  def pack_tool
    if Platform.is_windows? then
      require 'ziptool'
      ZipTool.new
    else
      require 'tarball'
      Tarball.new
    end
  end
  
end
