require 'repository_tool'

class Redmine < RepositoryTool

  class << self
    def load_path; false; end
  end
  
  Redmine.configure
  
  def initialize name, url, projectid
    
    super(name)
    
    @url = url
    @projectid = projectid
    @files_page_path = '/projects/' + @projectid + '/files'
    
    config = Jud::Config.instance.config['tools']['redmine'][@url]
    if config.key? 'username' then
      @username = config['username']
      @password = config['password']
    else
      config['username'] = ''
      config['password'] = ''
      abort 'Please edit ' + Jud::Config.instance.filename.to_s + ' to set username and password for redmine server ' + @url
    end
    
  end
  
  def login
    
    require 'mechanize'
    
    agent = Mechanize.new
    
    agent.get(URI.join(@url, '/login')) do |login_page|
      login_page.form_with(:action => '/login') do |login_form|
        login_form.username = @username
        login_form.password = @password
      end.submit
    end
    
    agent
    
  end
  
  def exist? filename
    
    agent = login
    
    agent.get URI.join(@url, @files_page_path) do |files_page|
      file_link = files_page.link_with(:text => filename.basename.to_s)
      return (not file_link.nil?)
    end
    
    return false
    
  end
  
  def download filename
    
    agent = login
    agent.pluggable_parser.default = Mechanize::Download
    
    agent.get URI.join(@url, @files_page_path) do |files_page|
      file_link = files_page.link_with(:text => filename.basename.to_s)
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
    
    agent = login
        
    files_page_uri = URI.join(@url, @files_page_path + '/new')
    
    agent.get files_page_uri do |upload_page|
      puts Platform.blue('Upload ' + filename.to_s + ' to ' + files_page_uri.to_s)
      upload_page.form_with(:action => @files_page_path) do |upload_form|
        if upload_form.has_field? 'version_id' then
          #upload_form.set_fields :version_id => 'test'
        end
        upload_form.file_uploads.first.file_name = filename.to_s
      end.submit
    end
        
  end
  
end
