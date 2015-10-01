module Application
  
  $arguments = {}
  $projects = []
  $allprojects = {}
  
  def prj sym, args={}, &block
    $arguments[sym] = { :application => self.to_s, :options => {} }
    $arguments[sym].merge! args
    $projects = []
  end
  
  def projects appname=nil
    if appname.nil? then
      if $projects.empty? then
        deps = {}
        # Compute the dependencies for each project
        $arguments.each do |sym, options|
          proj = Object.const_get sym.to_s
          $projects << proj
          deps[proj] = project(sym).depends
        end
        # Determine the order to build the projects
        $projects.sort! do |proj1, proj2|
          if deps[proj1].include? proj2 then
            1
          elsif deps[proj2].include? proj1 then
            -1
          else
            0
          end
        end
      end
      $projects
    else
      projects.select{ |p| $arguments[p.name.to_sym][:application] == appname }
    end
  end
  
  def project sym
    Application::project sym
  end
  
  def Application::project sym
    if $allprojects.has_key? sym then
      $allprojects[sym]
    else
      prj = nil
      if $arguments.has_key? sym then
        prj = Object.const_get(sym.to_s).new $arguments[sym]
      else
        options = { :application => 'main', :options => {} }
        prj = Object.const_get(sym.to_s).new options
      end
      $allprojects[sym] = prj
      prj
    end
  end
  
  def options sym
    $arguments[sym]
  end
  
  def update    
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
  
  def build appname, proj = nil
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
    project(proj.name.to_sym).install_me
  end
    
  def deploy appname, projname = nil
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
    prj.deploy_this if prj.deploy_this?
  end
  
  def submit appname
    projects(appname).each do |proj|
      prj = project(proj.name.to_sym)
      if prj.class.submit_tool then
        puts Platform.yellow("Build and test project " + proj.name)      
        prj.submit
      else
        puts Platform.red("Not tool to submit #{proj.name}, so only build it")
        prj.install_me
      end
    end
  end
    
end
