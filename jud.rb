#!/usr/bin/env ruby

require 'pathname'

$juddir = Pathname.new(__FILE__).realpath.dirname
$:.unshift $juddir.join('Library').to_s
$:.unshift $juddir.join('Platforms').to_s
$:.unshift $juddir.join('Tools').to_s

require 'config'
require 'platform'
require 'rubygems/gem_runner'
require 'utilities'

at_exit { Jud::Config.instance.save }

$general_config = Jud::Config.instance.config['main']
$tools_config = Jud::Config.instance.config['tools']

AUTO_GEMS =
  [
   'mechanize',
   'zip'
  ]

module Kernel
  alias :require_orig :require
  def require name
    begin
      require_orig name
    rescue LoadError => e
      begin
        raise if not AUTO_GEMS.include? name
        # Prepare arguments
        args = ['install', '--verbose']
        args << '--user-install' if not File.writable? Gem.default_dir
        args << name
        # Get the current directory
        dir = File.absolute_path (File.dirname ENV['_'])
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
            puts (Platform.red "Can't install gem #{name}")
          end
        else
          puts (Platform.red ex)
          exit ex.exit_code
        end
      end
    end
  end
end

require 'git'
require 'svn'

case ARGV.first
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
      if klass.configured? and klass.guess url then
        puts Platform.green("#{url} looks like a Git repository")
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
          if klass.configured? then
            puts (Platform.green "Try to download with #{klass.name}")
            scm = klass.new url
            status = scm.checkout home
            throw :download_ok if status[0].success?
          end
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
      config['scm'] = scm.class.name
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
  Jud::Config.instance.config['main']['default'] = name
  exit
end

begin
  
  if not Jud::Config.instance.config['main'].include? 'default' then
    abort('Please, create a platform with jud create <repository> <platform>')
  end
  
  platform = $general_config['default']
  $platform_config = Jud::Config.instance.config['platforms'][platform]
  
  $platform = Platform.new platform
  $platform.load_composites
  $platform.load_tools
  
  repository = $platform_config['repository']
  $repository_config = $general_config['repositories'][repository]
  
  scm = $repository_config['scm']
  url = $repository_config['url']
  scm = Object.const_get(scm).new url

  case ARGV.first
  when 'enable'
    ARGV.shift
    $platform.setup ARGV.shift
    exit
  end
  
  $:.unshift $home.join('Projects').to_s
  
  require 'project'
  Dir.glob $home.join('Projects', '*.rb').to_s do |rb|
    load rb
  end
  
  $:.unshift $home.join('Applications').to_s
  require 'application'

  def load_application appname
    begin
      load $home.join('Applications', "#{appname.downcase}.rb").to_s
    rescue LoadError => e
      puts (Platform.red "Can't load application #{appname}")
      puts e
      exit 1
    end
  end
  
  case ARGV.first
  when 'help', nil
    print 'jud' +
      ' [branch <app> <branch>]' +
      ' [build <conf>]' +
      ' [test <conf>]' +
      ' [install <app> [+<opt>]*[-<opt>]*]' +
      ' [option <path1> <pathn>* <value>' +
      ' [options <app>]' +
      ' [tag <app> <tag>]' +
      ' [tags <app>]' +
      "\n"
  when 'branch'
    ARGV.shift
    app = Object.const_get(ARGV.shift).new
    app.scm_tool.branch app.src, ARGV.shift
  when 'build'
    ARGV.shift
    appname = ARGV.shift
    load_application appname
    if ARGV.length > 0 then
      Application.build appname, ARGV.shift
    else
      Application.build appname
    end
  when 'applications'
    puts 'Available applications'
    subsubclasses(Application).each do |c|
      puts "  #{c}"
    end
  when 'install'
    ARGV.shift
    name = ARGV.shift
    options = {}
    while ARGV.length > 0
      arg = ARGV.shift
      case arg[0]
      when '-'
        options[arg[1..-1].to_sym] = false
      when '+'
        options[arg[1..-1].to_sym] = true
      end
    end
    claz = Object.const_get(name)
    claz.new({ :application => 'main', :options => options }).install
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
    appname = ARGV.shift
    load_application appname
    Application.submit appname
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
    if ARGV.length > 0 then
      appname = ARGV.shift
      load_application appname
      Application.update
    end
  when 'upload'
    ARGV.shift
    name = ARGV.shift
    options = {}
    options[:version] = ARGV.shift if ARGV.length > 0
    app = Object.const_get(name).new(options)
    app.upload_this
  end
  
rescue Platform::Error, Tool::Error => e
  puts (Platform.red e)
end
