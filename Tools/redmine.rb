require 'mechanize'
require 'repository_tool'

class Redmine < RepositoryTool

  class << self
    def load_path; false; end
  end
  
  Redmine.configure
  
  def initialize url, projectid
    
    super()
    
    @url = url
    @projectid = projectid
    @files_page_path = '/projects/' + @projectid + '/files'
    @versions_page_path = '/projects/' + @projectid + '/versions'
    
    config = @config['servers'][@url]
    if config.key? 'username' and not config['username'].empty?
      @username = config['username']
      @password = config['password']
      @proxy_host = config['proxy_host']
      @proxy_port = config['proxy_port']
    else
      config['username'] = ''
      config['password'] = ''
      config['proxy_host'] = ''
      config['proxy_port'] = ''
      raise Error, "Please, edit #{Jud::Config.instance.filename.to_s} to set username and password for redmine server #{@url}."
    end
    
  end
  
  def login
    
    agent = Mechanize.new
    agent.set_proxy @proxy_host, @proxy_port if @proxy_host.length > 0
    
    begin
      agent.get(URI.join(@url, '/login')) do |login_page|
        login_page.form_with(:action => '/login') do |login_form|
          login_form.username = @username
          login_form.password = @password
        end.submit
      end
    rescue Mechanize::ResponseCodeError => e
      puts (Platform.red e)
      puts (Platform.red "Check your connection or your configuration file #{Jud::Config.instance.filename.to_s}")
      abort
    end
    
    agent
    
  end
  
  def agent
    @agent ||= login
  end
  
  def version_id version
    agent.get URI.join(@url, @versions_page_path) do |page|
      page.links_with(:text => version).each do |link|
        return $1 if link.uri.to_s =~ /\/versions\/(\d+)/
      end
    end
    return nil
  end
  
  def version! version
    uri = URI.join(@url, @versions_page_path + '/new')    
    agent.get uri do |page|
      puts Platform.blue("Create version #{version} at #{uri.to_s}")
      page.form_with(:action => @versions_page_path) do |form|
        form.set_fields 'version[name]' => version
      end.submit
    end
  end
  
  def exist? filename
    agent.get URI.join(@url, @files_page_path) do |page|
      file_link = page.link_with(:text => filename.basename.to_s)
      return (not file_link.nil?)
    end
    return false
  end
  
  def download filename
    agent.pluggable_parser.default = Mechanize::Download
    agent.get URI.join(@url, @files_page_path) do |page|
      file_link = page.link_with(:text => filename.basename.to_s)
      if file_link
        file_id = file_link.href.match(/download\/(\d+)/)[1].to_i
        agent.get(URI.join(@url, "/attachments/#{file_id}")).save(filename.to_s)
        puts Platform.blue('Download ' + filename.to_s)
      else
        puts Platform.red('No link to download ' + filename.basename.to_s)
      end
    end
    
  end
  
  def upload filename
    
    version = nil
    
    versionid = nil
    if version then
      versionid = version_id version
      version! version if versionid.nil?
      versionid = version_id version
    end
    
    uri = URI.join(@url, @files_page_path + '/new')
    
    agent.get uri do |page|
      puts Platform.blue("Upload #{filename.to_s} to #{uri.to_s}")
      page.form_with(:action => @files_page_path) do |form|
        if versionid then
          form.set_fields :version_id => versionid
        end
        form.file_uploads.first.file_name = filename.to_s
      end.submit
    end
    
  end
  
end
