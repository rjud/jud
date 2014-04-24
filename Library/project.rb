require 'config'

class Project
  
  class Error < RuntimeError; end
  
  attr_reader :name, :packdir, :scm_tool
  
  def initialize options={}
    self.class.languages.uniq!
    @options = options
    @name = self.class.name
    @scm_tool = self.class.scm_tool
    @app_config = $platform_config['projects']
    @config = @app_config[@name] 
    @install = prefix
    @packdir = $packdir
  end
  
  def project sym
    Application.project sym
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
    if @options.has_key? :application then
      $build.join @options[:application], dir
    else
      $build.join dir
    end
  end
  
  def prefix
    config = @app_config['separate_install_trees']
    unless config.boolean? then
      config = true
      @app_config['separate_install_trees'] = config = true
    end
    if config then
      dir = @name
      dir += "-#{@options[:version]}" if @options.has_key? :version
      dir += "-#{build_name}"
      prefix = $install.join dir
    else
      prefix = $install
    end
    prefix
  end
  
  def update
    build_types.each do |bt|
      update_this bt
    end
  end
  
  def install_dependency claz
    depend  = Application.project claz.name.to_sym
    if depend.packfile.exist? then
      depend.unpack_this
    elsif depend.class.repository and depend.class.repository.exist? depend.packfile then
      depend.download_this
      depend.unpack_this
    else
      puts Platform.yellow('[' + name + "] install dependency " + depend.name)
      depend.install_dependencies
      build_types.each do |bt|
        depend.checkout_this bt
        depend.patch_this bt
        depend.configure_this bt
        depend.build_this bt
        depend.install_this bt
      end
      depend.pack_and_upload_this
      puts Platform.yellow("[#{name}] dependency #{depend.name} is installed")
    end
    depend.register_this
  end
  
  def install_dependencies
    self.class.depends.each do |depend, cond|
      install = cond.nil? || @options[:options][cond]
      config = @app_config[depend.name]
      install = (not config.has_key? 'prefix') if install
      install_dependency depend if install
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
  
  def register_this
    @config['prefix'] = @install.to_s
  end
  
  def install
    install_dependencies
    instance_eval &self.class.env if self.class.env
    build_types.each do |bt|
      checkout_this bt
      patch_this bt
      configure_this bt
      build_this bt
      install_this bt
    end
    pack_and_upload_this
    register_this
  end
  
  def submit
    install_dependencies
    self.class.submit_tool.build_tool = self.class.build_tool
    self.class.submit_tool.scm_tool = self.class.scm_tool
    status = SubmitTool::OK
    build_types.each do |bt|
      src = srcdir bt
      build = builddir bt
      buildname = "#{@options[:version]} " if @options.has_key? :version
      buildname += "#{build_name}"
      @scm_tool.checkout src, @options if not File.directory? src
      s = self.class.submit_tool.submit src, build, @install, bt, buildname, @options[:options]
      status = s if s > status
    end
    pack_and_upload_this if pack? status
    @config['prefix'] = @install.to_s
  end
  
  def pack? status
    case status
    when SubmitTool::OK then true
    when SubmitTool::TESTS_NOK then true
    else false
    end
  end
  
  def packfilename
    filename = @name
    filename += "-#{@options[:version]}" if @options.has_key? :version
    filename += "-#{build_name}"
    filename += ".#{self.class.pack_tool.ext}"
    filename
  end
  
  def packfile
    Pathname.new(@packdir).join packfilename
  end
  
  def pack_and_upload_this
    begin
      pack_this
      upload_this if self.class.repository and @options.has_key? :version
    rescue SocketError => e
      puts (Platform.red "Can't upload the file #{packfilename}:\n#{e}")
    end
  end
  
  def pack_this
    puts Platform.blue("Pack #{packfile.basename.to_s}")
    self.class.pack_tool.pack packfile, @install
  end
  
  def unpack_this
    puts Platform.blue("Unpack #{packfile.basename.to_s} to #{@install.to_s}")
    self.class.pack_tool.unpack packfile, @install
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
    
    attr_reader :scm_tool, :alternate_scm_tool, :languages, :build_tool, :submit_tool, :repository, :env
    
    def pack_tool
      zip
      @pack_tool
    end
    
    def languages
      @languages ||= []
    end
        
    def build_types
      @build_types ||= []
    end
    
    def depends
      @depends ||= []
    end
    
    def depend_on name, cond=nil
      depends << [name, cond]
    end
    
    def add_build_type name
      @build_types << name
    end
    
    def setenv &block
      @env = block if block_given?
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
    
    def zip
      require 'ziptool'
      @pack_tool = ZipTool.new
    end
    
  end
  
end
