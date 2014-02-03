require 'open3'

class Platform
  
  class Error < RuntimeError; end
  
  UNIX  = 1 << 1
  WIN32 = 1 << 2
  
  attr_accessor :cmake_native_build_tool
  attr_accessor :cmake_native_compiler
  attr_accessor :cmake_generator
  attr_accessor :memcheck_tool
  
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
  
  def self.create platform, repository
    config = Jud::Config.instance.config['platforms'][platform]
    config['repository'] = repository
  end
  
  def load_env
    @cmake_native_compiler.load_env
  end
  
  # wd, safe, keep
  def execute cmd, options = {}
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
        lines << line if options.key? :keep and line.match(/#{options[:keep]}/)
      end
      exit_status = wait_thr.value
    end
    if options[:safe] or exit_status.success? then
      [exit_status, lines.last]
    else
      raise Error, "Command #{cmd} failed"
    end
  end
  
  def find_executable exe, optional=false
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each do |ext|
        filename = File.join(path, "#{exe}#{ext}")
        if File.executable? filename
          puts Platform.green('Found ' + exe + ': ' + filename) 
          return filename
        end
      end
    end
    puts (Platform.red "Can't find #{exe}")
    if optional
      return nil
    else
      raise Error, "Can't find executable #{exe}"
    end
  end
  
end
