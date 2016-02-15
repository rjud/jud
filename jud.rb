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
require 'tool'

$config = Jud::Config.instance.config
if not $config.include? 'platforms'
  $config['platforms'] = {}
  $config['platforms'].default_proc = $config.default_proc
  Platform.create 'default', 'default' if not $config['platforms'].include? 'default'
end

at_exit { Jud::Config.instance.save }

if Platform.is_windows?
  if (Jud::Version.new RUBY_VERSION) > (Jud::Version.new '2.2')
    puts (Platform.red "ruby #{RUBY_VERSION} is not supported under Windows because nokogiri is not available")
    exit
  end
end

require 'kernel_patch'

$general_config = Jud::Config.instance.config['main']
$tools_config = Jud::Config.instance.config['tools']
$tools_passwords = Jud::Config.instance.passwords['tools']
$do_nothing = false

$appname = $general_config['application']
platform = $general_config['platform']

while true
  case ARGV.first
  when nil
    cmd = 'ocra'
    break
  when '--platform'
    ARGV.shift
    platform = ARGV.shift
  when '--appname'
    ARGV.shift
    $appname = ARGV.shift
  when 'configure'
    cmd = ARGV.shift
    break
  else
    cmd = ARGV.shift
    # Clear the environment variables so that we have a clean environment.
    if Platform.is_windows?
      ENV['PATH'] = ENV['SystemRoot'] + '\system32'
    else
      ENV['PATH'] = '/usr/bin:/bin'
    end
    break
  end
end

begin
  
  $platform_config = Jud::Config.instance.config['platforms'][platform]
  
  puts Platform.green("*************************************")
  puts Platform.green("    Platform #{platform}             ")
  puts Platform.green("      #{$platform_config['home']}    ")
  puts Platform.green("      #{$platform_config['src']}     ")
  puts Platform.green("      #{$platform_config['build']}   ")
  puts Platform.green("      #{$platform_config['install']} ")
  puts Platform.green("*************************************")
  
  $platform = Platform.new platform

  repository = $platform_config['repository']
  
  $repository_config = $general_config['repositories'][repository]
  
  scm = $repository_config['scm']
  url = $repository_config['url']

  if scm.size > 0
    load "Tools/#{scm.downcase}.rb"
    scm = Object.const_get("Jud::Tools::#{scm}").new url
  end

  if $home
    $:.unshift $home.join('Projects').to_s
    $:.unshift $home.join('Applications').to_s
  end
  
  require 'project'
  require 'application'
  
  begin
    
    if $appname == 'main'
    # Nothing to do
    else
      load "#{$appname.downcase}.rb"
    end
    
    puts Platform.green("****************************")
    puts Platform.green("    Application #{$appname}  ")
    puts Platform.green("****************************")
    
  rescue LoadError => e
    puts (Platform.red "Can't load application #{$appname}")
    puts (Platform.red e)
    puts (Platform.red e.backtrace.join("\n\t"))
    exit 1
  end
  
  load "Commands/#{cmd}.rb"
  Jud.send cmd.to_sym
  
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
