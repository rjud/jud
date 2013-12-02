require 'open3'

class Platform
  
  attr_accessor :cmake_native_build_tool
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
  
  def execute cmd, wd=nil, safe=false, keep=nil
    if wd
      FileUtils.mkdir_p wd.to_s if not wd.directory?
      Dir.chdir wd.to_s
    end
    puts Platform.blue(wd.nil? ? cmd : wd.to_s + '> ' + cmd)
    exit_status = nil
    lines = []
    Open3.popen2e cmd do |stdin, stdout_err, wait_thr|
      while line = stdout_err.gets
        puts line
        lines << line if keep and line.match(/#{keep}/)
      end
      exit_status = wait_thr.value
    end
    if safe or exit_status.success? then
      [exit_status, lines.last]
    else
      abort
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
    puts Platform.red("Can't find " + exe)
    if optional
      return nil
    else
      abort
    end
  end
  
end
