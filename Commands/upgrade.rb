module Jud
  def self.upgrade
    url = 'https://github.com/rjud/jud.git'
    Platform.set_env_proxy if Platform.use_proxy? url
    (Jud::Tools::Git.new url).update $juddir
    Platform.unset_env_proxy if Platform.use_proxy? url
    scm.update $home
  end
end
