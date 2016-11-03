require 'mechanize'
require 'repository_tool'

module Jud::Tools
  class Redmine < RepositoryTool
    
    class << self
      def pure_ruby; true; end
    end
    
    def initialize url, projectid, options={}
      
      super options
    
      @url = url
      @projectid = projectid
      @files_page_path = '/projects/' + @projectid + '/files'
      @versions_page_path = '/projects/' + @projectid + '/versions'
      
      config = @config['servers'][@url]
      passwords = @passwords['servers'][@url]
      if config.key? 'username' and not config['username'].empty?
        @username = config['username']
        @password = passwords['password']
        #@proxy_host = config['proxy_host']
        #@proxy_port = config['proxy_port']
        @proxy_host = ''
        @proxy_port = ''
      else
        config['username'] = ''
        passwords['password'] = ''
        #config['proxy_host'] = ''
        #config['proxy_port'] = ''
        raise Error, "Please, edit #{Jud::Config.instance.config_file.filename.to_s} and #{Jud::Config.instance.passwords_file.filename.to_s} to set username and password for redmine server #{@url}."
      end
      
    end
    
    def login
      
      agent = Mechanize.new
      agent.set_proxy @proxy_host, @proxy_port if @proxy_host.length > 0
      
      begin
        uri = URI.parse File.join(@url, '/login') # URI.join doesn't work
        agent.get uri do |page|
          page.form_with(:action => uri.path) do |form|
            form.username = @username
            form.password = @password
          end.submit
        end
      rescue Mechanize::ResponseCodeError => e
        puts (Platform.red e)
        puts (Platform.red "Check your connection or your configuration file #{Jud::Config.instance.filename.to_s}")
        abort
      rescue Exception => e
        puts (Platform.red e)
        raise e
      end
      
      agent
      
    end
    
    def agent
      @agent ||= login
    end
    
    def version_id version
      uri = URI.parse File.join(@url, @versions_page_path)
      agent.get uri do |page|
        page.links_with(:text => version).each do |link|
          return $1 if link.uri.to_s =~ /\/versions\/(\d+)/
        end
      end
      return nil
    end
    
    def version! version
      uri1 = URI.parse File.join(@url, @versions_page_path)
      uri2 = URI.parse File.join(@url, @versions_page_path, '/new')    
      agent.get uri2 do |page|
        puts Platform.blue("Create version #{version} at #{uri1.to_s}")
        begin
          page.form_with(:action => uri1.path) do |form|
            form.set_fields 'version[name]' => version
          end.submit
        rescue => e
          puts Platform.red("Can't create version:\n#{e}")
        end
      end
    end
    
    def file_id filename
      begin
        uri = URI.parse File.join(@url, @files_page_path)
        agent.get uri do |page|
          link = page.link_with(:text => filename.basename.to_s)
          return $1 if link.uri.to_s =~ /\/attachments\/download\/(\d+)\//
        end
      rescue Mechanize::ResponseCodeError => e
        return nil
      end
      return nil
    end
    
    def exist? filename
      uri = URI.parse File.join(@url, @files_page_path)
      puts Platform.blue("Check existence of #{filename} at #{uri}")
      begin
        agent.get uri do |page|
          link = page.link_with(:text => filename.basename.to_s)
          return (not link.nil?)
        end
      rescue Mechanize::ResponseCodeError => e
        puts e
      rescue SocketError => e
        msg = "Can't check the existence of the file #{filename}:\n#{e}"
        puts (Platform.red msg)
      rescue Exception => e
        puts (Platform.red e)
      end
      return false
    end
    
    def download filename
      uri1 = URI.parse File.join(@url, @files_page_path)
      agent.pluggable_parser.default = Mechanize::Download
      agent.get uri1 do |page|
        link = page.link_with(:text => filename.basename.to_s)
        if link
          id = link.href.match(/download\/(\d+)/)[1].to_i
          uri2 = URI.parse File.join(@url, "/attachments/#{id}")
          agent.get(uri2).save(filename.to_s)
          puts Platform.blue('Download ' + filename.to_s)
        else
          puts Platform.red('No link to download ' + filename.basename.to_s)
        end
      end
      
    end
    
    def upload filename, options={}
      
      version = if options.has_key? :version then options[:version] else nil end
      
      versionid = nil
      begin
        if version then
          versionid = version_id version
          version! version if versionid.nil?
          versionid = version_id version
          return if versionid.nil?
        end
      rescue Mechanize::ResponseCodeError => e
      rescue SocketError => e
        puts (Platform.red "Can't upload the file #{filename}:\n#{e}")
        return
      end
      
      action = File.join(@url, @files_page_path)
      uri = URI.parse File.join(action, 'new')
      
      puts Platform.blue("Upload #{filename.to_s} to #{uri.to_s}")    
      begin
        agent.get uri do |page|
          page.form_with(:action => URI.parse(action).path) do |form|
            if versionid then
              form.set_fields :version_id => versionid
            end
            form.file_uploads.first.file_name = filename.to_s
          end.submit
        end
      rescue Mechanize::ResponseCodeError => e
        puts (Platform.red e)
      end
      
    end
    
    def delete filename
      
      id = file_id filename
      uri = URI.parse File.join(@url, @files_page_path)
      
      puts(Platform.blue "Delete #{filename.to_s} from #{uri.to_s}")
      
      agent.get uri do |page|
        uri2 = URI.parse File.join(@url, 'attachments', id)
        agent.post(uri2, {'_method' => 'delete', 'authenticity_token' => page.at('meta[@name="csrf-token"]')[:content]})
      end
      
    end
    
  end
end
