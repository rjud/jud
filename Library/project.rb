require 'config'
require 'context'

class Project
  
  class Error < RuntimeError; end
  
  attr_reader :name, :packdir, :scm_tool, :config, :options, :major, :minor, :revision
  attr_accessor :repository
  
  def initialize options={}
    self.class.languages.uniq!
    @options = options
    @name = self.class.name
    @scm_tool = self.class.scm_tool
    @repository = self.class.repository
    @app_config = $platform_config['projects']
    @config = @app_config[@name][options[:application]]
    @install = prefix
    @packdir = $packdir
    if @options.has_key? :version then
      @major, @minor, @revision = @options[:version].split '.'
      @options.merge! ({ :major => @major, :minor => @minor, :revision => @revision})
    end
  end
  
  def project sym
    require 'application'
    Application::project sym
  end
  
  def build_name
    case self.class.languages.size
    when 0 then
      return $platform.build_name
    when 1 then
      language = self.class.languages.first
      composite = $platform.get_composite_for_language(language)
      return composite.build_name
    else
      name = $platform.build_name
      self.class.languages.each do |language|
        composite = $platform.get_composite_for_language language
        name += '-' + composite.short_build_name
      end
      return name
    end
  end
  
  def checkoutdir build_type
    dir = @name
    dir += "-#{@options[:version]}" if @options.has_key? :version
    $src.join dir
  end
  
  def srcdir build_type = :Debug
    checkoutdir build_type
  end
  
  def builddir build_type
    dir = @name
    dir += "-#{@options[:version]}" if @options.has_key? :version
    dir += "-#{build_name}"
    dir += "-#{build_type.downcase}" if build_type
    $build.join @options[:application], dir
  end
  
  def prefix
    return Pathname.new @config['prefix'] if @config.has_key? 'prefix'
    separate = @app_config['separate_install_trees']
    unless separate.boolean? then
      @app_config['separate_install_trees'] = separate = true
    end
    if separate then
      dir = @name
      dir += "-#{@options[:version]}" if @options.has_key? :version
      dir += "-#{build_name}"
      prefix = $install.join @options[:application], dir
    else
      prefix = $install.join @options[:application]
    end
    prefix
  end
  
  # All dependencies (by recursion) after applying conditions
  def all_dependencies
    all = []
    all_depends.each do |depend, cond|
      dep = project(depend.name.to_sym)
      if to_be_installed? depend, cond then
        all << dep
        all.concat dep.all_dependencies
      end
    end
    all.uniq!
    all
  end
  
  def update
    srcs = []
    bts = []
    build_types.each do |bt|
      src = srcdir bt
      if not srcs.include? src then
        srcs << src
        bts << bt
      end
    end
    bts.each do |bt|
      update_this bt
    end
  end
    
  def install_dependency claz
    depend = project claz.name.to_sym
    depend.install_dependencies
    if depend.packfile.exist? then
      depend.unpack_this
    elsif depend.class.repository and depend.class.repository.exist? depend.packfile then
      depend.download_this
      depend.unpack_this
    else
      puts Platform.yellow('[' + name + "] install dependency " + depend.name)
      depend.load_env
      build_types.each do |bt|
        depend.checkout_this bt
        depend.patch_this bt
        depend.configure_this bt
        depend.build_this bt
        depend.install_this bt
      end
      depend.pack_this if depend.pack_this?
      depend.upload_this if depend.upload_this?
      puts Platform.yellow("[#{name}] dependency #{depend.name} is installed")
    end
    depend.deploy_this if depend.deploy_this?
    depend.register_this
    depend.trash_this
  end
  
  def to_be_installed? depend, cond
    cond.nil? or @options[:options][cond]
  end
  
  def install_dependency? depend, cond
    return false if not to_be_installed? depend, cond
    prf = Application::project(depend.name.to_sym).prefix
    if not File.directory? prf
	  puts Platform.red("[#{name}] dependency #{depend.name} not found in directory #{prf}")
	  return true 
	end
    return false
  end
  
  def install_dependencies
    all_depends.each do |depend, cond|
      install_dependency depend if install_dependency? depend, cond
    end
  end
  
  # Dependencies and conditions from the meta_description and from the options
  def all_depends
    if self.class.build_tool.nil? then
      self.class.depends
    else
      self.class.build_tool.depends(self) + self.class.depends
    end
  end
  
  # Useful method to compute dependencies and conditions from the options
  def auto_depends args, cond=nil
    case args
    when Hash
      [].tap do |depends|
        args.each do |prj, arg|
          depends << [Application::project(prj), cond]
        end
      end
    else
      []
    end
  end
  
  def self.project_eval args
    eval = project_evals args
    raise Error, "Only one argument:\n#{eval}" if eval.size != 1
    eval.first
  end
  
  def self.project_evals args
    case args
    when Proc
      [args.call]
    when Hash
      [].tap do |evals|
        args.each do |prj, arg|
          evals <<
            case arg
            when Symbol
              Application::project(prj).send arg
            when Array
              Application::project(prj).send arg[0], *arg[1..-1]
            when Proc
              arg.call Application::project(prj)
            else
              raise Error, "project.rb self.project_evals: Not implemented for #{arg.class}"
            end
        end
      end
    else
      raise Error, "project.rb self.project_evals: Not implemented for #{args.class}"
    end
  end
  
  def load_env
    puts (Platform.blue "Load environment")
    load_binenv
    load_libenv
    puts (Platform.yellow "PATH: #{ENV['PATH']}")
    if Platform.is_linux? then
      puts (Platform.yellow "LD_LIBRARY_PATH: #{ENV['LD_LIBRARY_PATH']}")
    elsif Platform.is_darwin? then
      puts (Platform.yellow "DYLD_LIBRARY_PATH: #{ENV['DYLD_LIBRARY_PATH']}")
    elsif Platform.is_windows? then
      # Nothing to do. It is PATH.
    else
      raise Error, "project.rb load_end: Not implemented"
    end
    puts (Platform.yellow "JAVA_HOME: #{ENV['JAVA_HOME']}")
    puts (Platform.yellow "CLASSPATH: #{ENV['CLASSPATH']}")
    if Platform.is_windows? then
      puts (Platform.yellow "INCLUDE: #{ENV['INCLUDE']}")
      puts (Platform.yellow "LIB: #{ENV['LIB']}")
      puts (Platform.yellow "LIBPATH: #{ENV['LIBPATH']}")
    end
  end
  
  def load_binenv
    self.class.binenv.each do |args|
      Project.project_evals(args).each do |path|
        if Platform.is_windows? then
          ENV['PATH'] = path << ";" << ENV['PATH']
        else
          ENV['PATH'] = path << ":" << ENV['PATH']
        end
      end
    end
  end
  
  def load_libenv  
    self.class.libenv.each do |args|
      Project.project_evals(args).each do |path|
        if Platform.is_windows? then
          ENV['PATH'] = path << ";" << ENV['PATH']
        elsif Platform.is_linux? then
          ENV['LD_LIBRARY_PATH'] = path << ":" << ENV['LD_LIBRARY_PATH']
        elsif Platform.is_darwin? then
          ENV['DYLD_LIBRARY_PATH'] = path << ":" << ENV['DYLD_LIBRARY_PATH']
        else
          raise Error, "project.rb load_libenv: Not implemented"
        end
      end
    end
  end
  
  def checkout_this build_type
    src = checkoutdir build_type
    if not File.directory? src then
	  puts (Platform.red "Can't find the sources of #{name} in the directory #{src}")
      safe = (not self.class.alternate_scm_tool.nil?)
      if not @scm_tool.nil?
        @scm_tool.checkout src, self, @options.merge({:safe => safe})
      end
      if not self.class.alternate_scm_tool.nil?
        self.class.alternate_scm_tool.checkout src, self
      end
      @config.delete 'patches'
    end
  end
  
  def update_this build_type
    src = srcdir build_type
    if File.directory? src then
      @scm_tool.update src
    else
      checkout_this build_type
    end
  end
  
  def patch_this build_type
    Dir.glob $home.join('Patches', @name, '*.patch').to_s do |patch|
      require 'patch'
      @config['patches'] = [] if not @config.has_key? 'patches'
      patchname = File.basename patch, '.patch'
      if @config['patches'].include? patchname then
        puts (Platform.red "Patch #{patchname} already applied")
      else
        Patch.new.patch (srcdir build_type), patch
        @config['patches'] << patchname
      end
    end
  end

  def copy_sources build_type
    src = srcdir build_type
    build = builddir build_type
    puts (Platform.blue "Files must be copied from #{src} to #{build}")
    Dir[src.join('**', '**')].each do |f|
      new = f.sub src.to_s, build.to_s
      if File.directory? f then
        FileUtils.mkdir_p new
      else
        begin
          # Can't throw Errno::EEXIST ???
          if Platform.is_windows?
            if File.exists? new
              puts (Platform.blue "Files have already been copied. In case of failure, please remove the directory #{build}")
              return
            end
          end
          File.symlink f, new
        rescue Errno::EEXIST => e
          puts (Platform.blue "Files have already been copied. In case of failure, please remove the directory #{build}")
          return
        rescue Exception => e
          puts (Platform.red "Symlink not supported: #{e}")
          abort
        end
      end
    end
  end
  
  def configure_this build_type
    src = srcdir build_type
    build = builddir build_type
    FileUtils.mkdir_p build unless Dir.exist? build
    copy_sources build_type if self.class.in_source
    if self.class.configure_block.nil? then
      return if self.class.build_tool.nil?
      self.class.build_tool.configure src, build, @install, build_type, self, @options[:options]
    else
      Dir.chdir build
      Context.new(self, build_type).instance_eval &self.class.configure_block
    end
  end
  
  def build_types
    [:Debug, :Release] + self.class.build_types
  end
  
  def build_this build_type
    build = builddir build_type
    if self.class.build_block.nil? then
      return if self.class.build_tool.nil?
      self.class.build_tool.build build, @options[:options]
    else
      Dir.chdir build
      Context.new(self, build_type).instance_eval &self.class.build_block
    end
  end
  
  def install_this build_type
    build = builddir build_type
    if self.class.install_block.nil? then
      return if self.class.build_tool.nil?
      self.class.build_tool.install (Pathname.new build)
    else
      Dir.chdir build
      Context.new(self, build_type).instance_eval &self.class.install_block
    end
  end
  
  def get_version
    if @options.has_key? :version then
      @options[:version]
    elsif @scm_tool
      @scm_tool.get_revision (srcdir build_types[0]), @options
    else
      nil
    end
  end
  
  def register_this
    # Register version
    @config['version'] = get_version if get_version
  end
  
  def trash_this
    puts (Platform.blue "Cleaning...")
    timestamp = DateTime.now.strftime '%Y%m%d%H%M%S%L'
    FileUtils.mkdir_p $trash unless $trash.directory?
    Dir.chdir $trash
    build_types.each do |bt|
      if (builddir bt).directory? then
        new_name = builddir(bt).basename.to_s + '-' + timestamp
        begin
          FileUtils.mv (builddir bt), new_name, :verbose => true 
        rescue Errno::EACCES => e
          puts (Platform.red e)
        end
      end
      if (srcdir bt).directory? then
        new_name = srcdir(bt).basename.to_s + '-' + timestamp
        begin
          FileUtils.mv (srcdir bt), new_name, :verbose => true
        rescue Errno::EACCES => e
          puts (Platform.red e)
        end
      end
    end
    @config.delete 'patches'
  end
  
  def deploy_this?
    true
  end
  
  def deploy_this
    # Go to /usr
    usr = $install.join 'usr'
    FileUtils.mkdir_p usr.to_s if not usr.directory?
    Dir.chdir usr.to_s
    # Print a message
    puts (Platform.blue "Deploy #{build_name} to #{usr.to_s}")
    # Name of the files file
    filesname = prefix.dirname.join (prefix.basename.to_s + '.files')
    # Get the files already installed
    installed_files = [].tap do |files|
      if File.exists? filesname then
        File.open filesname, 'r' do |file|
          files.concat file.readlines.map{ |l| l.chomp }
        end
      end
    end
    # Check that they are really installed
    installed_files.delete_if { |f| not File.symlink? f }
    # Check
    all_files = []
    alert_files = []
    Dir[prefix.join('**', '**')].each do |f|
      new = f.sub prefix.to_s + '/', ''
      new_abs = usr.join(new).to_s
      if File.directory? f then
        FileUtils.mkdir_p new if not File.directory? new
      else
        all_files << new_abs
        if File.exists? new and not installed_files.include? new_abs then
          alert_files << new_abs
        end
      end
    end
    files_to_link = all_files - installed_files
    files_to_unlink = installed_files - all_files
    # Raise an exception if alert_files is not empty
    if alert_files.size > 0 then
      msg = "The following files have been installed by a previous package:\n"
      alert_files.each do |f|
        msg += "#{f}\n"
        FileUtils.remove_file f if File.exists? f
      end
      puts (Platform.red msg)
    end
    # Create symlinks to /usr
    files_to_link.each do |f|
      old = f.sub usr.to_s, prefix.to_s
      puts "Link #{f} -> #{old}"
      begin
        File.symlink old, f
      rescue Exception => e
        puts (Platform.red e)
      end
    end
    # Remove symlinks from /usr
    files_to_unlink.each do |f|
      puts "Unlink #{f}"
      File.unlink f
    end
    # Save the list of files
    dir = Pathname.new(filesname).dirname.to_s
    FileUtils.mkdir_p dir unless File.exists? dir
    File.open filesname, 'w' do |file|
      all_files.each do |f|
        file.write("#{f}\n")
      end
    end
  end
  
  def install_me
    install_dependencies
    load_env
    build_types.each do |bt|
      checkout_this bt
      patch_this bt
      configure_this bt
      build_this bt
      install_this bt
    end
    pack_this if pack_this?
    upload_this if upload_this?
    deploy_this if deploy_this?
    register_this
  end
  
  def submit
    # Variables
    self.class.submit_tool.build_tool = self.class.build_tool
    self.class.submit_tool.scm_tool = self.class.scm_tool
    status = SubmitTool::OK
    # Install dependencies
    install_dependencies
    # Prepare environment
    load_env
    # Submit for each build
    build_types.each do |bt|
      src = checkoutdir bt
      build = builddir bt
      buildname = "#{@options[:version]} " if @options.has_key? :version
      buildname += "#{build_name}"
      @scm_tool.checkout src, self, @options if not File.directory? src
      patch_this bt
      s = self.class.submit_tool.submit src, build, @install, bt, buildname, @options[:options]
      status = s if s > status
      install_this bt
    end
    pack_this if pack_this?
    # Upload if good
    upload_this if upload_this_after_submit? status
    deploy_this if deploy_this?
    register_this
  end
  
  def upload_this_after_submit? status
    if @repository.nil? then
      false
    else
      case status
      when SubmitTool::OK then true
      when SubmitTool::TESTS_NOK then true
      else false
      end
    end
  end
  
  def pack_tool
    $platform.pack_tool
  end

  def packsrcfilename ext
    filename = @name
    filename += "-#{@options[:version]}" if @options.has_key? :version
    filename += ext
  end
  
  def packsrcfile ext
    Pathname.new(@packdir).join (packsrcfilename ext)
  end
  
  def packfilename
    filename = @name
    filename += "-#{@options[:version]}" if @options.has_key? :version
    filename += "-#{build_name}"
    filename += ".#{pack_tool.ext}"
    filename
  end
  
  def packfile
    Pathname.new(@packdir).join packfilename
  end
  
  def pack_this?
    true
  end
  
  def upload_this?
    @repository and @options.has_key? :version
  end
  
  def pack_this
    puts Platform.blue("Pack #{packfile.basename.to_s}")
    pack_tool.pack packfile, @install
  end
  
  def unpack_this
    puts Platform.blue("Unpack #{packfile.basename.to_s} to #{@install.to_s}")
    PackTool.unpack pack_tool, packfile, @install
  end
  
  def download_this
    @repository.download packfile
  end
  
  def upload_this
    if @repository.exist? packfile then
      @repository.delete packfile
    end
    @repository.upload packfile, @options
  end
  
  # Dependencies after applying conditions
  def depends
    depends = []
    all_depends.each do |depend, cond|
      depends << depend if cond.nil? or @options[:options][cond.to_sym]
    end
    depends
  end
  
  def lookin; []; end
  
  class << self
    
    attr_reader :scm_tool, :alternate_scm_tool, :languages, :build_tool, :submit_tool, :repository, :binenv, :libenv, :configure_block, :build_block, :install_block, :in_source
    
    def languages
      @languages ||= []
    end
        
    def build_types
      @build_types ||= []
    end
    
    def depends
      @depends ||= []
    end
    
    def binenv
      @binenv ||= []
    end
    
    def libenv
      @libenv ||= []
    end
    
    def depend_on name, cond=nil
      depends << [name, cond]
    end
    
    def add_build_type name
      @build_types << name
    end

    def insource
      @in_source = true
    end
    
    def c
      require 'c'
      languages << Jud::C
    end
    
    def cxx
      require 'cxx'
      languages << Jud::Cxx
    end
    
    def java
	  require 'java'
      languages << Jud::Java
    end
    
    def ant &block
      require 'Tools/ant'
      @build_tool = Jud::Tools::Ant.new
      @build_tool.instance_eval &block if block_given?
    end
    
    def autotools &block
      require 'autotools'
      @build_tool = AutoTools.new
      @build_tool.instance_eval &block if block_given?
    end
    
    def cmake &block
      require 'cmake'
      @build_tool = Jud::Tools::CMake.new
      @build_tool.instance_eval &block if block_given?
    end
    
    def ctest &block
      require 'ctest'
      @submit_tool = CTest.new
      @submit_tool.instance_eval &block if block_given?
    end
    
    def cvs url, modulename
      require 'cvs'
      @scm_tool = CVS.new url, modulename
    end
    
    def eclipse &block
      require 'eclipse'
      @build_tool = Eclipse.new
      @build_tool.instance_eval &block if block_given?
    end
    
    def git url, options={}
      require 'git'
      @scm_tool = Git.new url, options
    end
    
    def nmake &block
      require 'nmake'
      @build_tool = NMake.new
      @build_tool.instance_eval &block if block_given?
    end
    
    def redmine url, projectid
      require 'redmine'
      @repository = Redmine.new url, projectid
    end
    
    def svn url, options={}
      require 'svn'
      @scm_tool = SVN.new url, options
    end
    
    def wget url, packtool, options={}
      require 'wget'
      @alternate_scm_tool = Wget.new url, packtool, options
    end

    def configure &block
      @configure_block = block_given? ? block : nil
    end

    def build &block
      @build_block = block_given? ? block : nil
    end

    def install &block
      @install_block = block_given? ? block : nil
    end
    
  end
  
end
