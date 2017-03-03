# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|


    # Configure Port Forwarding To The Box
    #config.vm.network "forwarded_port", guest: 80, host: 8080
    #config.vm.network "forwarded_port", guest: 443, host: 44300
    #config.vm.network "forwarded_port", guest: 3306, host: 33060

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "debian/contrib-jessie64"

  # Create a private network, which allows host-only access to the machine using a specific IP.
  config.vm.network "private_network", ip: "192.168.33.23"

  config.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "/tmp/authorized_keys"

  # Share an additional folder to the guest VM. The first argument is the path on the host to the actual folder.
  # The second argument is the path on the guest to mount the folder.
  config.vm.synced_folder "./www", "/var/www/html"

  config.vm.boot_timeout = 600

  # Define the bootstrap file: A (shell) script that runs after first setup of your box (= provisioning)
  config.vm.provision :shell, :path => "bootstrap.sh"

end
