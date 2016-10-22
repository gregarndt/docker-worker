Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"

  config.vm.synced_folder ENV['HOME'], ENV['HOME']

  config.vm.provision "shell", path: 'vagrant.sh'
  # Requires vagrant-reload plugin
  config.vm.provision :reload
end
