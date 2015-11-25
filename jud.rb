#!/usr/bin/env ruby

require 'pathname'

$juddir = Pathname.new(__FILE__).realpath.dirname
$:.unshift $juddir.to_s
$:.unshift $juddir.join('Library').to_s
$:.unshift $juddir.join('Projects').to_s
$:.unshift $juddir.join('Applications').to_s

require 'config'
require 'platform'
require 'project'
require 'rubygems/gem_runner'
require 'utilities'
require 'version'

if Platform.is_windows?
  if (Jud::Version.new RUBY_VERSION) > (Jud::Version.new '2.2')
    puts (Platform.red "ruby #{RUBY_VERSION} is not supported under Windows because nokogiri is not available")
    exit
  end
end

at_exit { Jud::Config.instance.save }

$general_config = Jud::Config.instance.config['main']
$tools_config = Jud::Config.instance.config['tools']
$tools_passwords = Jud::Config.instance.passwords['tools']
$do_nothing = false

AUTO_GEMS =
  {
  'antwrap' => 'Antwrap',
  'mechanize' => 'mechanize',
  'zip' => 'zip'
}

# Change the implementation of symlink to support Windows mklink

if RUBY_PLATFORM =~ /mswin32|cygwin|mingw|bccwin/
  
  require 'open3'
  
  class << File
    
    #$PRINT_SYMLINK_MESSAGE = true
    
    def symlink old_name, new_name
      cmd = "mklink /H #{new_name.gsub '/', '\\'} #{old_name.gsub '/', '\\'}"
      stdin, stdout, stderr, wait_thr = Open3.popen3 'cmd.exe', "/c #{cmd}"
      stdout.read # Keep it to flush
      puts (Platform.red stderr.read) if not stderr.eof?
      wait_thr.value.exitstatus
      #if not symlink? new_name
      #  FileUtils.copy_file old_name, new_name
      #  if $PRINT_SYMLINK_MESSAGE
      #    puts (Platform.red "Symlinks are not supported or enabled on your platform. This privilege " +
      #          "may be granted to you by an administator. Run secpol.msc. " +
      #          "Open security settings > Local Policies > User Rights Assignment. " +
      #          " Find \"Create symbolic links\", edit the properties and add you."
      #          )
      #    $PRINT_SYMLINK_MESSAGE = false
      #  end
      #end
    end
    
    def symlink? file_name
      stdin, stdout, stderr, wait_thr = Open3.popen3 'cmd.exe', "/c dir #{file_name.gsub '/', '\\'} | find \"SYMLINK\""
      wait_thr.value.exitstatus
    end
    
  end
  
end

module Kernel
  alias :require_orig :require
  def require name
    begin
      require_orig name
    rescue LoadError => e
      begin
        raise if not AUTO_GEMS.has_key? name
        # Prepare arguments
        args = ['install', '--verbose']
        args << '--user-install' if not File.writable? Gem.default_dir
        args << AUTO_GEMS[name]
        # Get the current directory
        dir = File.absolute_path (File.dirname __FILE__)
        # Set proxy if needed
        if Platform.use_proxy? 'https://rubygems.org/' then
          ENV['http_proxy'] = Platform.proxy_url
        end
        # Run the gem command
        args_s = ''.tap { |s| args.each { |arg| s.concat "#{arg} " } }
        puts (Platform.blue "#{dir}> gem #{args_s}")
        Gem::GemRunner.new.run args
        # Unset proxy
        ENV.delete 'http_proxy'
      rescue Gem::SystemExitException => ex
        if ex.exit_code == 0 then
          begin
            require_orig name
            puts (Platform.blue "Gem #{name} successfully installed")
          rescue LoadError => e
            puts (Platform.red "Can't install gem #{name}:\n #{e}")
          end
        else
          puts (Platform.red ex)
          exit ex.exit_code
        end
      end
    end
  end
end

Jud::Config.instance.config['main']['repositories']['default']['dir'] = Jud::ConfigurationFile.configdir.to_s
Jud::Config.instance.config['platforms']['default']['repository'] = 'default'
$platform = Platform.new 'default'

require 'Tools/git'
require 'Tools/svn'

case ARGV.first
when 'configure'
  Dir.glob ($juddir + 'Tools' + '*.rb').to_s do |rb|
    load rb
  end
  ObjectSpace.each_object(Class).select{ |c| c < Tool }.each do |c|      
    c.configure
  end
    ARGV.shift
  exit
when 'download' then
  ARGV.shift
  url = ARGV.shift
  dir = Pathname.new(ARGV.shift)
  Dir.mkdir dir.to_s if not File.directory? dir.to_s
  dir = dir.realpath
  home = dir.join('home')
  status = nil
  scm = nil
  subsubclasses(SCMTool).each do |klass|
    begin
      if klass.guess url then
        puts Platform.green("#{url} looks like a #{Tool.toolname klass} repository")
        scm = klass.new url
        status = scm.checkout home
      end
    rescue Platform::Error => e
      puts (Platform.red e)
    end
  end
  catch :download_ok do
    if not status or not status[0].success? then
      puts (Platform.green "Can't guess the type of the repository #{url}")
      subsubclasses(SCMTool).each do |klass|
        begin
          puts (Platform.green "Try to download with #{klass.name}")
          scm = klass.new url
          status = scm.checkout home, nil
          throw :download_ok if status[0].success?
        rescue Platform::Error => e
          puts (Platform.red e)
        end
      end
      abort
    end
  end
  namefile = home.join 'NAME'
  File.open(namefile.to_s, "r") do |file|
    name = file.gets
    if name.empty? then
      puts "The file NAME is empty."
      abort
    else
      config = Jud::Config.instance.config['main']['repositories'][name]
      config['scm'] = Tool.toolname scm.class
      config['url'] = url
      config['dir'] = dir.to_s
      config['home'] = home.to_s
      exit
    end
  end
when 'create' then
  ARGV.shift
  repository = ARGV.shift
  name = ARGV.shift
  Platform.create repository, name
  Jud::Config.instance.config['main']['platform'] = name
  exit
end

if not Jud::Config.instance.config['main'].include? 'platform' then
  puts Platform.red('Please, create a platform with jud create <repository> <platform>')
  exit
end

platform = $general_config['platform']
$platform_config = Jud::Config.instance.config['platforms'][platform]

puts Platform.green("*************************************")
puts Platform.green("    Platform #{platform}             ")
puts Platform.green("      #{$platform_config['home']}    ")
puts Platform.green("      #{$platform_config['src']}     ")
puts Platform.green("      #{$platform_config['build']}   ")
puts Platform.green("      #{$platform_config['install']} ")
puts Platform.green("*************************************")

$platform = Platform.new platform
#$platform.load_composites
  
repository = $platform_config['repository']
$repository_config = $general_config['repositories'][repository]

scm = $repository_config['scm']
url = $repository_config['url']
scm = Object.const_get("Jud::Tools::#{scm}").new url

case ARGV.first
when 'configure'
  if ($install + 'Tools').directory?
    ($install + 'Tools').each_child do |child|
      if child.directory?
        ENV['PATH'] = ($install + 'Tools' + child + 'bin').to_s + ";" + ENV['PATH']
      end
    end
  end
  Dir.glob ($juddir + 'Tools' + '*.rb').to_s do |rb|
    load rb
  end
  ObjectSpace.each_object(Class).select{ |c| c < Tool }.each do |c|
    c.configure
  end
  exit
end

begin
  
  # Clear the environment variables so that we have a clean environment.
  if Platform.is_windows?
    ENV['PATH'] = ENV['SystemRoot'] + '\system32'
  else
    ENV['PATH'] = '/usr/bin:/bin'
  end
  
  require 'project'
  require 'application'
  
  $:.unshift $home.join('Projects').to_s
  $:.unshift $home.join('Applications').to_s
  
  appname = $general_config['application']
  begin
    if appname == 'main'
      # Nothing to do
    else
      load "#{appname.downcase}.rb"
    end
  rescue LoadError => e
    puts (Platform.red "Can't load application #{appname}")
    puts (Platform.red e)
    exit 1
  end
  
  puts Platform.green("****************************")
  puts Platform.green("    Application #{appname}  ")
  puts Platform.green("****************************")

  case ARGV.first
  when nil
    puts "I am loading all requirements for ocra."
    puts "If you want some help, `jud help` could be useful for you."
    Dir.glob ($juddir + 'Library' + '*.rb').to_s do |rb|
      require (File.basename rb)
    end
    Dir.glob ($juddir + 'Platforms' + '*.rb').to_s do |rb|
      require ('Platforms/' + (File.basename rb) )
    end
    Dir.glob ($juddir + 'Tools' + '*.rb').to_s do |rb|
      require ('Tools/' + (File.basename rb) )
    end
    Dir.glob ($juddir + 'Projects' + '*.rb').to_s do |rb|
      require (File.basename rb)
    end
    Dir.glob ($juddir + 'Applications' + '*.rb').to_s do |rb|
      require (File.basename rb)
    end
    case RbConfig::CONFIG['host_os']
    when /mswin|mingw/
      require 'win32ole'
    end
    require 'http/cookie_jar/abstract_store'
    require 'http/cookie_jar/hash_store'
    require 'net/ftp'
  when 'help'
    puts 'jud'
    puts ' [branch <branch>]'
    puts ' [configure]'
    puts ' [build [<project>]]'
    puts ' [submit [CONTINUOUS|EXPERIMENTAL|NIGHTLY] [project]]'
    puts ' [deploy <project>]'
    puts ' [install [<app>] [+<opt>]*[-<opt>]*]'
    puts ' [option <path1> <pathn>* <value>'
    puts ' [options <project>]'
    puts ' [tag <tag>]'
    puts ' [tags]'
  when 'branch'
    ARGV.shift
    app = Object.const_get(ARGV.shift).new
    app.scm_tool.branch app.src, ARGV.shift
  when 'build'
    ARGV.shift
    if ARGV.length > 0 then
      Application.build appname, ARGV.shift
    else
      Application.build appname
    end
  when 'deploy'
    ARGV.shift
    if ARGV.length > 0
      Application.deploy appname, ARGV.shift
    else
      Application.deploy appname
    end
  when 'applications'
    puts 'Available applications'
    subsubclasses(Application).each do |c|
      puts "  #{c}"
    end
  when 'dependencies'
    ARGV.shift
    if ARGV.length > 0
      Application.dependencies appname, ARGV.shift
    else
      Application.dependencies appname
    end
  when 'enable'
    ARGV.shift
    toolname = ARGV.shift
    exit if $platform_config['tools'].include? toolname
    if Jud::Config.instance.config['tools'].key? toolname
      $platform_config['tools'] << toolname
    else
      puts (Platform.red "I am sorry but I did not find a tool named #{toolname}.")
      puts (Platform.red "Could I suggest you to run `jud configure` or `jud list tools` ?")
    end
  when 'install'
    ARGV.shift
    if ARGV.length > 0 then
      Application.install appname, ARGV.shift
    else
      Application.install appname
    end
    #options = {}
    #while ARGV.length > 0
    #  arg = ARGV.shift
    #  case arg[0]
    #  when '-'
    #    options[arg[1..-1].to_sym] = false
    #  when '+'
    #    options[arg[1..-1].to_sym] = true
    #  end
    #end
  when 'list'
    ARGV.shift
    $do_nothing = true
    case ARGV.shift
    when 'applications'
      Dir.glob ($juddir + 'Applications' + '*.rb').to_s do |rb|
        load rb
      end
      Dir.glob ($home + 'Applications' + '*.rb').to_s do |rb|
        load rb
      end
      $applications.each do |app|
        puts "  #{app}"
      end
    when 'platforms'
      Jud::Config.instance.config['platforms'].each do |name, _|
        puts "  #{name}"
      end
    when 'tools'
      tools = {}
      Jud::Config.instance.config['tools'].each do |name, config|
        tools[config['instanceof']] = []
      end
      Jud::Config.instance.config['tools'].each do |name, config|
        tools[config['instanceof']] << name
      end
      tools.each do |classname, instances|
        puts "  #{classname}"
        instances.each do |instance|
          puts "  |--#{instance}"
        end
      end
    end
  when 'options'
    ARGV.shift
    claz = Object.const_get(ARGV.shift)
    claz.build_tool.options.each do | key, option |
      puts key, "\t" + (option[1].nil? ? 'No description' : option[1].to_s)
    end
  when 'optionadd'
    ARGV.shift
    h = Jud::Config.instance.config
    paths = ARGV.shift.split('.')
    paths[0..-2].each { |p| h = h[p] }
    h[paths.last] = [] if not h.include? paths.last
    h[paths.last] << ARGV.shift
  when 'optionset'
    ARGV.shift
    h = Jud::Config.instance.config
    paths = ARGV.shift.split('.')
    paths[0..-2].each { |p| h = h[p] }
    h[paths.last] = ARGV.shift
  when 'pack'
    ARGV.shift
    app = Object.const_get(ARGV.shift).new
    app.pack
  when 'submit'
    ARGV.shift
    mode = SubmitTool::EXPERIMENTAL
    if ARGV.length > 0 then
      arg = ARGV.shift
      if arg == 'EXPERIMENTAL'
        mode = SubmitTool::EXPERIMENTAL
      elsif arg == 'CONTINUOUS'
        mode = SubmitTool::CONTINUOUS
      elsif arg == 'NIGHTLY'
        mode = SubmitTool::NIGHTLY
      else
        prjname = arg
      end
    end
    prjname = ARGV.shift if ARGV.length > 0
    Application.submit appname, prjname, { :mode => mode }
  when 'switch'
    ARGV.shift
    arg = ARGV.shift
    if arg == 'main'
      Jud::Config.instance.config['main']['application'] = 'main'
    elsif Jud::Config.instance.config['platforms'].key? arg
      Jud::Config.instance.config['main']['platform'] = arg
    else
      begin
        load $home.join('Applications', "#{arg.downcase}.rb").to_s
        Jud::Config.instance.config['main']['application'] = arg
        puts (Platform.green "Switch to application #{arg}")
      rescue LoadError => e
        puts (Platform.red "#{arg} is not a platform and I can't load an application with this name.")
        puts (Platform.red "")
        puts e
      end
    end
  when 'tag'
    ARGV.shift
    app = Object.const_get(ARGV.shift).new
    app.class.scm_tool.tag app.src, ARGV.shift
  when 'tags'
    ARGV.shift
    app = Object.const_get(ARGV.shift).new
    app.class.scm_tool.tags app.srcdir :Debug
  when 'update'
    ARGV.shift
    scm.update $home
    Application.update
  when 'upload'
    ARGV.shift
    project = ARGV.shift
    Application.upload appname, project
  end
  
rescue Interrupt => e
  puts
  puts (Platform.red "Why do you want to interrupt me ?")
  exit 0
rescue Platform::Error, Project::Error, Tool::Error => e
  puts (Platform.red "An error has been caught : could you do something for me ?")
  puts e
  puts e.backtrace
  exit -1
end
