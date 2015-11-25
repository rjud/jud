require 'config'
require 'context'

class Project
  
  class Error < RuntimeError; end
  
  attr_reader :name, :packdir, :scm_tool, :config, :options, :major, :minor, :revision, :contexts
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
    @contexts = {}
    build_types.each { |bt| @contexts[bt] = Context.new(self, bt) }
    build_env
  end
  
  def project sym
    require 'application'
    Application::project sym
  end
  
  def build_name
    buildname = $platform.build_name
    self.class.languages.uniq!
    self.class.languages.each do |l|
      buildname = ($platform.get_compiler l).build_name buildname, l
    end
    buildname
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
  
  def deploydir
    $install.join @options[:application], 'usr'
  end
  
  def bindir
    self.class.bin_dir.nil? ? prefix + 'bin' : self.class.bin_dir
  end
  
  def datadir
    self.class.data_dir.nil? ? prefix + 'share' : self.class.data_dir
  end
  
  def includedir
    self.class.include_dir.nil? ? prefix + 'include' : self.class.include_dir
  end
  
  def libdir
    self.class.lib_dir.nil? ? prefix + 'lib' : self.class.lib_dir
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
  
  def install_me options={}
    install_dependencies
    if not options[:force] and prefix.directory?
      puts (Platform.yellow "#{self.class.name} is already installed")
      return
    end
    if not options[:force] and packfile.exist?
      unpack_this
    elsif not options[:force] and self.class.repository and self.class.repository.exist? depend.packfile
      download_this
      unpack_this
    else
      build_types.each do |bt|
        @contexts[bt].push
        print_env
        checkout_this bt
        patch_this bt
        configure_this bt
        build_this bt
        install_this bt
        @contexts[bt].pop
      end
      pack_this if pack_this?
      upload_this if upload_this?
    end
    deploy_this if deploy_this?
    register_this
    trash_this if options[:trash]
  end
  
  def install_dependency claz
    depend = project claz.name.to_sym
    puts Platform.yellow("[#{name}] install dependency #{depend.name}")
    depend.install_me(trash: true)
    puts Platform.yellow("[#{name}] dependency #{depend.name} is installed")
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
      self.class.depends.uniq { |dep, cond| dep }
    else
      (self.class.build_tool.depends(self) + self.class.depends).uniq { |dep,cond| dep }
    end
  end
  
  def show_dependencies indent
    puts "#{' ' * indent}+--#{self.name}"
    all_depends.each do |depend, cond|
      if to_be_installed? depend, cond
        prj = Application::project(depend.name.to_sym)
        prj.show_dependencies (indent + 3) 
      end
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
  
  def build_env
    build_types.each do |bt|
      # Environment from compilers
      self.class.languages.each do |language|
        compiler = $platform.get_compiler language
        compiler.setenv @contexts[bt]
      end
      # Enviroment from tools
      @alternate_scm_tool.setenv @contexts[bt] unless @alternate_scm_tool.nil?
      @build_tool.setenv @contexts[bt] unless @build_tool.nil?
      @scm_tool.setenv @contexts[bt] unless @scm_tool.nil?
      @submit_tool.setenv @contexts[bt] unless @submit_tool.nil?
      # Environment from this project
      self.class.binenv.each do |args|
        Project.project_evals(args).each do |path|
          @contexts[bt].appenv 'PATH', path
        end
      end      
      self.class.libenv.each do |args|
        Project.project_evals(args).each do |path|
          if Platform.is_windows? then
            @contexts[bt].appenv 'PATH', path
          elsif Platform.is_linux? then
            @contexts[bt].appenv 'LD_LIBRARY_PATH', path
          elsif Platform.is_darwin? then
            @contexts[bt].appenv 'DYLD_LIBRARY_PATH', path
          else
            raise Error, "project.rb libenv: Not implemented"
          end
        end
      end
    end
  end
  
  def print_env
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
      puts (Platform.yellow "Platform: #{ENV['Platform']}")
    end
  end
    
  def checkout_this build_type
    src = checkoutdir build_type
    if not File.directory? src
      puts (Platform.red "I can't find the sources of #{name} #{@options[:version]}. I will try to download them.")
      safe = (not self.class.alternate_scm_tool.nil?)
      if @scm_tool.nil?
        puts (Platform.red "There is no SCM tool to download them.")
      else
        @scm_tool.checkout src, self, @options.merge({:safe => safe})
      end
      if not File.directory? src
        if self.class.alternate_scm_tool.nil?
          puts (Platform.red "There is no alternative way to download a package. Do you really think that I can guess it ?")
        else
          self.class.alternate_scm_tool.checkout src, self
        end
      end
      @config.delete 'patches'
      if not File.directory? src
        raise Error, "I really can't find the sources of #{name} #{@options[:version]} :-(. I propose you to download them and extract them in the directory #{src}. Thank you for your help !"
      end
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
      require 'Tools/patch'
      @config['patches'] = [] if not @config.has_key? 'patches'
      patchname = File.basename patch, '.patch'
      if @config['patches'].include? patchname then
        puts (Platform.red "Patch #{patchname} already applied")
      else
        Jud::Tools::Patch.new.patch (srcdir build_type), patch
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
      @contexts[build_type].instance_eval &self.class.configure_block
    end
  end
  
  def build_types
    [:Debug, :Release] + self.class.build_types
  end
  
  def build_this build_type
    build = builddir build_type
    if self.class.build_block.nil? then
      return if self.class.build_tool.nil?
      self.class.build_tool.build build, build_type, @options[:options]
    else
      Dir.chdir build
      @contexts[build_type].instance_eval &self.class.build_block
    end
  end
  
  def install_this build_type
    build = builddir build_type
    if self.class.install_block.nil? then
      return if self.class.build_tool.nil?
      self.class.build_tool.install build, build_type
    else
      Dir.chdir build
      @contexts[build_type].instance_eval &self.class.install_block
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
  
  def files_to_deploy
    installed_files = Dir[bindir.join('**', '**')]
    installed_files += Dir[libdir.join('**', '**')] if not Platform.is_windows?
    installed_files += Dir[datadir.join('**', '**')]
    installed_files
  end
  
  def deploy_this
    # Create the deployment directory if it doesn't exist
    FileUtils.mkdir_p deploydir.to_s if not deploydir.directory?
    Dir.chdir deploydir.to_s
    # Print a message
    puts (Platform.blue "Deploy #{build_name} to #{deploydir.to_s}")
    # Name of the files file
    filesname = prefix.dirname.join (prefix.basename.to_s + '.files')
    # Get the files already deployed
    deployed_files = [].tap do |files|
      if File.exists? filesname then
        File.open filesname, 'r' do |file|
          files.concat file.readlines.map{ |l| l.chomp }
        end
      end
    end
    # Check that they are really deployed
    deployed_files.delete_if { |f| not File.exists? f }
    #   Check the files to be deployed
    #   If a deployed file is not included in the list of the known deployed files,
    # create an alert for it (it is probably installed by another project).
    all_files = []
    alert_files = []
    files_to_deploy.each do |f|
      new = f.sub prefix.to_s + '/', ''
      new_abs = deploydir.join(new).to_s
      if not File.directory? f then
        all_files << new_abs
        if File.exists? new and not deployed_files.include? new_abs then
          alert_files << new_abs
        end
      end
    end
    # Get the files to be deployed or unlinked
    files_to_link = all_files - deployed_files
    files_to_unlink = deployed_files - all_files
    # Print a message if alert_files is not empty
    if alert_files.size > 0 then
      msg = "The following files have been installed by a previous package. They will be removed.\n"
      alert_files.each do |f|
        msg += "  #{f}\n"
        FileUtils.remove_file f if File.exists? f
      end
      puts (Platform.red msg)
    end
    # Create some symlinks in deploydir
    files_to_link.each do |f|
      old = f.sub deploydir.to_s, prefix.to_s
      puts "Link #{f} to #{old}"
      begin
        FileUtils.mkdir_p (File.dirname f) if not File.directory? (File.dirname f)
        if Platform.is_windows?
          FileUtils.copy_file old, f
        else
          File.symlink old, f
        end
      rescue Exception => e
        puts (Platform.red e)
      end
    end
    # Remove some symlinks from deploydir
    files_to_unlink.each do |f|
      puts "Unlink #{f}"
      File.unlink f
    end
    # Update installed files under Windows
    if Platform.is_windows?
      deployed_files.each do |f|
        old = f.sub deploydir.to_s, prefix.to_s
        begin
          if (File.mtime old) > (File.mtime f)
            puts (Platform.blue "Updating #{f}")
            FileUtils.copy_file old, f 
          end
        rescue Errno::ENOENT => e
          puts (Platform.red e)
        end
      end
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
    
  def submit options={}
    # Variables
    self.class.submit_tool.build_tool = self.class.build_tool
    self.class.submit_tool.scm_tool = self.class.scm_tool
    status = SubmitTool::OK
    # Install dependencies
    install_dependencies
    # Submit for each build
    build_types.each do |bt|
      @contexts[bt].push
      print_env
      src = srcdir bt
      build = builddir bt
      buildname = ""
      buildname += "#{@options[:version]} " if @options.has_key? :version
      buildname += "#{build_name}"
      buildname += " #{bt}"
      @scm_tool.checkout src, self, @options if not File.directory? src
      patch_this bt
      s = self.class.submit_tool.submit self, src, build, @install, bt, buildname, options[:mode], @options[:options]
      status = s if s > status
      install_this bt
      @contexts[bt].pop
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
    
    attr_reader :scm_tool, :alternate_scm_tool, :languages, :build_tool, :submit_tool, :repository, :binenv, :libenv, :configure_block, :build_block, :install_block, :in_source, :bin_dir, :data_dir, :include_dir, :lib_dir
    
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
      languages << Jud::Languages::C
    end
    
    def cxx
      require 'cxx'
      languages << Jud::Languages::Cxx
    end
    
    def java
      require 'java'
      languages << Jud::Languages::Java
    end
    
    def ant &block
      require 'Tools/ant'
      @build_tool = Jud::Tools::Ant.new
      @build_tool.instance_eval &block if block_given?
    end
    
    def autotools &block
      require 'Tools/autotools'
      @build_tool = Jud::Tools::AutoTools.new
      @build_tool.instance_eval &block if block_given?
    end
    
    def cmake &block
      require 'Tools/cmake'
      @build_tool = Jud::Tools::CMake.new
      @build_tool.instance_eval &block if block_given?
    end
    
    def ctest &block
      require 'Tools/ctest'
      @submit_tool = Jud::Tools::CTest.new
      @submit_tool.instance_eval &block if block_given?
    end
    
    def cvs url, modulename
      require 'Tools/cvs'
      begin
        @scm_tool = Jud::Tools::CVS.new url, modulename
      rescue Platform::Error
        @scm_tool = nil
      end
    end
    
    def eclipse &block
      require 'Tools/eclipse'
      @build_tool = Jud::Tools::Eclipse.new
      @build_tool.instance_eval &block if block_given?
    end
    
    def git url, options={}
      require 'Tools/git'
      begin
        @scm_tool = Jud::Tools::Git.new url, options
      rescue Platform::Error
        @scm_tool = nil
      end
    end
    
    def nmake &block
      require 'Tools/nmake'
      @build_tool = Jud::Tools::NMake.new
      @build_tool.instance_eval &block if block_given?
    end
    
    def redmine url, projectid
      require 'Tools/redmine'
      @repository = Jud::Tools::Redmine.new url, projectid
    end
    
    def svn url, options={}
      require 'Tools/svn'
      @scm_tool = Jud::Tools::SVN.new url, options
    end
    
    def wget url, options={}
      require 'Tools/wget'
      @alternate_scm_tool = Jud::Tools::Wget.new url, options
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

    def bindir path
      @bin_dir = path
    end
    
    def datadir path
      @data_dir = path
    end
    
    def includedir path
      @include_dir = path
    end
    
    def libdir path
      @lib_dir = path
    end
    
  end
  
end
