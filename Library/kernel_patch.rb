AUTO_GEMS =
  {
    'antwrap' => 'Antwrap',
    'mechanize' => 'mechanize',
    'zip' => 'zip'
  }

module Kernel
  alias :require_orig :require
  def require name
    begin
      require_orig name
    rescue LoadError => e
      begin
        puts e
        raise if not AUTO_GEMS.has_key? name
        # Prepare arguments
        args = ['install', '--verbose']
        args << '--user-install' if not File.writable? Gem.default_dir
        args << AUTO_GEMS[name]
        # Get the current directory
        dir = File.absolute_path (File.dirname __FILE__)
        # Set proxy if needed
        if Platform.use_proxy? 'https://rubygems.org/' then
          ENV['http_proxy'] = Platform.proxy_url
        end
        # Run the gem command
        args_s = ''.tap { |s| args.each { |arg| s.concat "#{arg} " } }
        puts (Platform.blue "#{dir}> gem #{args_s}")
        Gem::GemRunner.new.run args
        # Unset proxy
        ENV.delete 'http_proxy'
      rescue Gem::SystemExitException => ex
        if ex.exit_code == 0 then
          begin
            require_orig name
            puts (Platform.blue "Gem #{name} successfully installed")
          rescue LoadError => e
            puts (Platform.red "Can't install gem #{name}:\n #{e}")
          end
        else
          puts (Platform.red ex)
          exit ex.exit_code
        end
      end
    end
  end
end
