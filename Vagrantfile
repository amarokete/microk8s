Vagrant.configure('2') do |config|
  # Uncomment this to disable VBGuest plugin
  # config.vbguest.auto_update = false

  config.vm.box = 'ubuntu/bionic64'

  # Ubuntu releases a new box nightly, so this can get annoying
  config.vm.box_check_update = false

  # Forward ports
  config.vm.network 'forwarded_port', guest: 80,   host: 8080
  config.vm.network 'forwarded_port', guest: 443,  host: 8443
  config.vm.network 'forwarded_port', guest: 8080, host: 9080
  config.vm.network 'forwarded_port', guest: 6443, host: 9443
  config.vm.network 'forwarded_port', guest: 9090, host: 9090

  # Use a bridged network for simplicity
  config.vm.network 'public_network'

  # Sync the kubernetes folder
  config.vm.synced_folder './examples', '/home/vagrant/examples',
    owner: 'vagrant',
    group: 'vagrant',
    type: 'virtualbox'

  # VM customizations
  config.vm.provider 'virtualbox' do |vb|
    vb.name = 'kubernetes'
    vb.cpus = 2
    vb.memory = 4096
    vb.customize ['modifyvm', :id, '--cableconnected1', 'on']
    vb.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
    vb.customize ['modifyvm', :id, '--natdnsproxy1', 'on']
    vb.customize ['setextradata', :id, 'VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled', 0]
    vb.customize ['setextradata', :id, 'VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant', 1]
    vb.customize ['setextradata', :id, 'VBoxInternal2/SharedFoldersEnableSymlinksCreate/home_vagrant_examples', 1]
  end

  # Loop through the provision folder and run each script
  Dir.entries(File.join(Dir.pwd, 'vagrant', 'provisioners')).sort.each do |provisioner|
    if provisioner.end_with? '.sh'
      config.vm.provision provisioner,
        # Uncomment this to disable provisioning
        # run: 'never',
        # You "shouldn't" use sudo inside of a script, and instead run your scripts privileged
        # However, since we have passwordless sudo, it's easier this way
        privileged: false,
        type: 'shell',
        path: "./vagrant/provisioners/#{provisioner}",
        env: {
          'KUBERNETES_VERSION' => '1.13',
          'KUBERNETES_CHANNEL' => 'stable',

          'HELM_CHANNEL' => 'stable',

          'COCKPIT_VERSION' => '187-1',
          'COCKPIT_UBUNTU_VERSION' => '18.04.1',
          'COCKPIT_FEDORA_VERSION' => '29',

          'KUBECTX_VERSION' => '0.6.3',
          'MICRO_VERSION' => '1.4.1'
        }
    end
  end
end
