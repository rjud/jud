require 'set'

module Application
  
  # Global map that contains all the arguments of a project.
  # ==== Contents
  # * +:application+ - Name of the owning application
  # * +:options+ - Options to be given to the project
  # * +:as_dependency+ - To be considered as a dependency
  $arguments = {}
  
  # Global list that contains all the project classes (reserved to an intern usage).
  # The projects are sorted by dependency order.
  $sorted_project_classes = []
  
  # Global map that contains all the project instances.
  $projects = {}
  
  # Global list of the known applications
  $applications = Set.new []
  
  # Add a project to this application.
  # ==== Attributes
  # * +:sym+ - Class symbol of a project
  # * +:args+ - Arguments of this project
  def prj sym, args={}, &block
    $arguments[sym] = {} unless $arguments.key? sym
    $arguments[sym][:application] = self.to_s
    $applications.add self
    $arguments[sym][:as_dependency] = false
    $arguments[sym][:options] = {} unless $arguments[sym].key? :options    
    $arguments[sym].merge! args
    if args.key? :options_to_merge
      $arguments[sym][:options].merge! args[:options_to_merge]
      args[:options_to_merge].each { |key, value| $arguments[sym][:options].delete key if value.nil? }
      $arguments[sym].delete :options_to_merge
    end
    args.each { |key, value| $arguments[sym].delete key if value.nil? }
    # Load the project definition file.
    load "#{sym.to_s.downcase}.rb"
    # Reinitialize the ordered project list, so that project order be recomputed.
    $sorted_project_classes = []
  end
  
  # Add a project to this application as a dependency.
  # Dependencies are built if necessary.
  def dep sym, args={}, &block
    if block_given?
      prj sym, args, block
    else
      prj sym, args
    end
    $arguments[sym][:as_dependency] = true
  end
  
  def projects appname=nil
    if appname.nil? then
      if $sorted_project_classes.empty? then
        deps = {}
        # Compute the dependencies for each project
        $arguments.each do |sym, options|
          proj = Object.const_get sym.to_s
          $sorted_project_classes << proj
          deps[proj] = project(sym).depends
        end
        # Determine the order to build the projects
        $sorted_project_classes.sort! do |proj1, proj2|
          if deps[proj1].include? proj2 then
            1
          elsif deps[proj2].include? proj1 then
            -1
          else
            0
          end
        end
      end
      $sorted_project_classes
    else
      projects
        .select{ |p| $arguments[p.name.to_sym][:application] == appname }
        .select{ |p| $arguments[p.name.to_sym][:as_dependency] == false }
    end
  end
  
  def project sym
    if $projects.has_key? sym then
      $projects[sym]
    else
      prj = nil
      load "#{sym.to_s}.rb"
      if $arguments.has_key? sym then
        prj = Object.const_get(sym.to_s).new $arguments[sym]
      else
        options = { :application => 'main', :options => {} }
        prj = Object.const_get(sym.to_s).new options
      end
      $projects[sym] = prj
      prj
    end
  end
  
  module_function :project
  
  def options sym
    $arguments[sym]
  end
  
  def Application.update    
    all = []
    projects.each do |p|
      all << project(p.name.to_sym)
      all.concat project(p.name.to_sym).all_dependencies
    end
    all.uniq!
    all.each do |p|
      p.update
    end
  end
  
  def Application.build appname, proj = nil
    if proj.nil? then
      projects(appname).each do |prj|
        build_one prj
      end
    else
      prj = Object.const_get proj
      build_one prj
    end
  end
  
  def build_one proj
    puts Platform.yellow("Build project " + proj.name)
    project(proj.name.to_sym).install_me(force: true)
  end
  
  def Application.install appname, proj=nil
    if proj.nil?
      projects(appname).each do |prj|
        install_one prj
      end
    else
      prj = Object.const_get proj
      install_one prj
    end
  end
  
  def install_one proj
    puts (Platform.yellow "Install project #{proj.name}")
    project(proj.name.to_sym).install_me
  end
  
  def Application.dependencies appname, proj=nil
    if proj.nil? then
      projects(appname).each do |prj|
        dependencies_one prj
      end
    else
      prj = Object.const_get proj
      dependencies_one prj
    end
  end
  
  def dependencies_one proj
    project(proj.name.to_sym).show_dependencies 0
  end
  
  def Application.deploy appname, projname = nil
    if projname.nil?
      projects(appname).each do |prj|
        deploy_one prj
      end
    else
      prj = Object.const_get projname
      deploy_one prj
    end
  end
  
  def deploy_one proj
    puts Platform.yellow "Deploy project #{proj.name}"
    prj = project(proj.name.to_sym)
    if File.directory? prj.prefix
      prj.deploy_this if prj.deploy_this?
    else
      prj.install_me
    end
  end
  
  def Application.submit appname, projname = nil, options={}
    if projname.nil?
      projects(appname).each do |prj|
        submit_one prj, options
      end
    else
      prj = Object.const_get projname
      submit_one prj, options
    end
  end
  
  def submit_one proj, options={}
    prj = project(proj.name.to_sym)
    if prj.class.submit_tool then
      puts Platform.yellow("Build and test project " + prj.name)
      prj.submit options
    else
      puts Platform.red("Not tool to submit #{proj.name}, so only install it")
      prj.install_me
    end
  end
  
  def Application.upload appname, projname
    prj = project(projname.to_sym)
    prj.upload_this
  end
    
end
