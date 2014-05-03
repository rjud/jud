require 'config'

class Project
  
  class Error < RuntimeError; end
  
  attr_reader :name, :packdir, :scm_tool, :config
  
  def initialize options={}
    self.class.languages.uniq!
    @options = options
    @name = self.class.name
    @scm_tool = self.class.scm_tool
    @app_config = $platform_config['projects']
    @config = @app_config[@name][options[:application]]
    @install = prefix
    @packdir = $packdir
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
  
  def srcdir build_type
    dir = @name
    dir += "-#{@options[:version]}" if @options.has_key? :version
    $src.join dir
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
  
  def all_dependencies
    all = []
    self.class.depends.each do |depend, cond|
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
    if depend.packfile.exist? then
      depend.unpack_this
    elsif depend.class.repository and depend.class.repository.exist? depend.packfile then
      depend.download_this
      depend.unpack_this
    else
      puts Platform.yellow('[' + name + "] install dependency " + depend.name)
      depend.install_dependencies
      load_env
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
    depend.register_this
  end
  
  def to_be_installed? depend, cond
    cond.nil? or @options[:options][cond]
  end
  
  def install_dependency? depend, cond
    return false if not to_be_installed? depend, cond
    prf = Application::project(depend.name.to_sym).prefix
    return true if not File.directory? prf
    return false
  end
  
  def install_dependencies
    self.class.depends.each do |depend, cond|
      install_dependency depend if install_dependency? depend, cond
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
    else
      raise Error, "Not implemented"
    end
  end
  
  def load_binenv
    self.class.binenv.each do |hash|
      hash.each do |prj, fun|
        path = project(prj).instance_eval fun.to_s
        if Platform.is_windows? then
          ENV['PATH'] = path << ";" << ENV['PATH']
        else
          ENV['PATH'] = path << ":" << ENV['PATH']
        end
      end
    end
  end
  
  def load_libenv  
    self.class.libenv.each do |hash|
      hash.each do |prj, fun|
        path = project(prj).instance_eval fun.to_s
        if Platform.is_windows? then
          ENV['PATH'] = path << ";" << ENV['PATH']
        elsif Platform.is_linux? then
          ENV['LD_LIBRARY_PATH'] = path << ":" << ENV['LD_LIBRARY_PATH']
        elsif Platform.is_darwin? then
          ENV['DYLD_LIBRARY_PATH'] = path << ":" << ENV['DYLD_LIBRARY_PATH']
        else
          raise Error, "Not implemented"
        end
      end
    end
  end
  
  def checkout_this build_type
    src = srcdir build_type
    if not File.directory? src then
      if not self.class.alternate_scm_tool.nil? then
        @scm_tool.checkout src, @options.merge({:safe => true})
        self.class.alternate_scm_tool.checkout src
      else
        @scm_tool.checkout src, @options
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
  
  def configure_this build_type
    if self.class.build_tool.nil? then return end
    src = srcdir build_type
    build = builddir build_type
    self.class.build_tool.configure src, build, @install, build_type, @options[:options]
  end
  
  def build_types
    [:Debug, :Release] + self.class.build_types
  end
  
  def build_this build_type
    if self.class.build_tool.nil? then return end
    self.class.build_tool.build (builddir build_type)
  end
  
  def install_this build_type
    if self.class.build_tool.nil? then return end
    self.class.build_tool.install (builddir build_type)
  end

  def get_version
    if @options.has_key? :version then
      @options[:version]
    else
      @scm_tool.get_revision (srcdir build_types[0]), @options
    end
  end
  
  def register_this
    @config['version'] = get_version
  end
  
  def install
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
      src = srcdir bt
      build = builddir bt
      buildname = "#{@options[:version]} " if @options.has_key? :version
      buildname += "#{build_name}"
      @scm_tool.checkout src, @options if not File.directory? src
      patch_this bt
      s = self.class.submit_tool.submit src, build, @install, bt, buildname, @options[:options]
      status = s if s > status
      install_this bt
    end
    pack_this if pack_this?
    # Upload if good
    upload_this if upload_this_after_submit? status
    register_this
  end
  
  def upload_this_after_submit? status
    if self.class.repository.nil? then
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
    self.class.repository and @options.has_key? :version
  end
  
  def pack_this
    puts Platform.blue("Pack #{packfile.basename.to_s}")
    pack_tool.pack packfile, @install
  end
  
  def unpack_this
    puts Platform.blue("Unpack #{packfile.basename.to_s} to #{@install.to_s}")
    pack_tool.unpack packfile, @install
  end
  
  def download_this
    self.class.repository.download packfile
  end
  
  def upload_this
    if self.class.repository.exist? packfile then
      self.class.repository.delete packfile
    end
    self.class.repository.upload packfile, @options
  end
  
  def depends
    depends = []
    self.class.depends.each do |depend, cond|
      depends << depend if cond.nil? or @options[:options][cond.to_sym]
    end
    depends
  end
    
  class << self
    
    attr_reader :scm_tool, :alternate_scm_tool, :languages, :build_tool, :submit_tool, :repository, :binenv, :libenv
    
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
            
    def c
      require 'c'
      languages << Jud::C
    end
    
    def cxx
      require 'cxx'
      languages << Jud::Cxx
    end
    
    def java
      languages << Java
    end
    
    def autotools &block
      require 'autotools'
      @build_tool = AutoTools.new
      @build_tool.instance_eval &block if block_given?
    end
    
    def cmake &block
      require 'cmake'
      @build_tool = CMake.new
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
    
    def git url
      require 'git'
      @scm_tool = Git.new url
    end
    
    def redmine url, projectid
      require 'redmine'
      @repository = Redmine.new url, projectid
    end
    
    def svn url, options={}
      require 'svn'
      @scm_tool = SVN.new url, options
    end
    
    def wget url, packtool
      require 'wget'
      @alternate_scm_tool = Wget.new url, packtool
    end
        
  end
  
end
