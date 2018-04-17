shared_examples_for 'users' do
  it 'creates user olduser with sudo' do
    expect(chef_run).to create_user_account('olduser')
    expect(chef_run).to install_sudo('olduser').with(
      user: 'olduser',
      runas: 'root',
      nopasswd: true
    )
  end

  it 'creates group newgroup' do
    expect(chef_run).to create_group('newgroup').with(
      gid: 2000
    )
  end

  it 'creates user testuser without sudo' do
    expect(chef_run).to create_user_account('testuser')
    expect(chef_run).to modify_shadow_attributes('testuser')
    expect(chef_run).to remove_sudo('testuser')
  end

  it 'creates user newuser1 with sudo' do
    expect(chef_run).to create_user_account('newuser1')
    expect(chef_run).to modify_shadow_attributes('newuser1')
    expect(chef_run).to install_sudo('newuser1').with(
      user: 'newuser1',
      runas: 'ALL',
      nopasswd: false
    )
  end

  it 'creates user newuser2 with sudo' do
    expect(chef_run).to create_user_account('newuser2').with(
      comment: 'another new user',
      uid: 2000,
      gid: 2000,
      shell: '/bin/dash',
      home: '/home/custom_home_directory',
      password: '$6$bLZbaeySMzRx7P29$cmmF4SbtnXe2Gc1cBc0fpnBUEPxrr8inn6SNq9xpcT7M/vM0FpZmGF105LWrGCValjJMqEtBALZOYayppwJAj/',
      ssh_keygen: true,
      ssh_keys: ['key1', 'key2']
    )
    expect(chef_run).to modify_shadow_attributes('newuser2').with(
      sp_lstchg: '2015-07-30',
      sp_expire: '2035-09-30',
      sp_min: 30,
      sp_max: 60,
      sp_inact: 5,
      sp_warn: 5
    )
    expect(chef_run).to install_sudo('newuser2').with(
      user: 'newuser2',
      runas: 'root',
      nopasswd: true,
      commands: ['/etc/init.d/httpd restart', '/sbin/iptables'],
      defaults: ['!requiretty', 'env_reset']
    )
    expect(chef_run).to create_group('newgroup2')
  end

  it 'removes user olduser' do
    expect(chef_run).to_not modify_shadow_attributes('olduser')
    expect(chef_run).to remove_user_account('olduser')
    expect(chef_run).to remove_sudo('olduser')
  end
end

shared_examples_for 'users override' do
  it 'creates user olduser with sudo' do
    expect(chef_run).to create_user_account('olduser')
    expect(chef_run).to install_sudo('olduser').with(
      user: 'olduser',
      runas: 'root',
      nopasswd: true
    )
  end

  it 'creates user newuser1 with sudo' do
    expect(chef_run).to create_user_account('newuser1')
    expect(chef_run).to modify_shadow_attributes('newuser1')
    expect(chef_run).to install_sudo('newuser1').with(
      user: 'newuser1',
      runas: 'ALL',
      nopasswd: false
    )
  end

  it 'creates user newuser2 without sudo' do
    expect(chef_run).to create_user_account('newuser2')
    expect(chef_run).to modify_shadow_attributes('newuser2')
    expect(chef_run).to remove_sudo('newuser2')
  end

  it 'removes user newuser3' do
    expect(chef_run).to_not modify_shadow_attributes('newuser3')
    expect(chef_run).to remove_user_account('newuser3')
    expect(chef_run).to remove_sudo('newuser3')
  end

  it 'removes user olduser' do
    expect(chef_run).to_not modify_shadow_attributes('olduser')
    expect(chef_run).to remove_user_account('olduser')
    expect(chef_run).to remove_sudo('olduser')
  end

  it 'creates groups from node tags' do
    expect(chef_run).to create_group('web').with(
      members: ['newuser1', 'newuser2']
    )
    expect(chef_run).to create_group('marketing').with(
      members: ['newuser1', 'newuser2']
    )
    expect(chef_run).to create_group('staging').with(
      members: ['newuser1', 'newuser2']
    )
  end

  it 'creates additional groups' do
    expect(chef_run).to create_group('facilities').with(
      members: ['newuser1', 'newuser2']
    )
  end
end
