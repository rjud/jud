module Jud
  def self.upgrade
    url = 'https://github.com/rjud/jud.git'
    Platform.set_env_proxy if Platform.use_proxy? url
    
    # Update Jud
    (Jud::Tools::Git.new url).update $juddir
    Platform.unset_env_proxy if Platform.use_proxy? url

    # Update $home
    $scm.update $home
    
    # Update application
    Application.update $appname
  end
end
