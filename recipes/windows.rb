#
# Cookbook Name:: system_users
# Recipe:: windows
#
# Copyright (C) 2018 Frederik S
#
# All rights reserved - Do Not Redistribute
#
# This recipe creates/modifies users that are read from an encrypted data bag.
# It also handles group membership and sudo access for these users.
# The data bag and item are defined in corresponding attributes.
# Please read the README file for details.

plugins = ['sysrandom', 'ruby-wmi']

plugins.each do |plugin|
  chef_gem plugin do
    action :install
    compile_time true
  end
  require plugin
end

users = data_bag_item(
  node['system_users']['data_bag'],
  node['system_users']['data_bag_item']
).to_hash.reject { |user, user_data| user == 'id' }

node_groups = node['system_users']['node_groups']

groups = {}

users.each do |username, user_data|
  user_data['action'] =
    if user_data['node_groups'] && (user_data['node_groups'] & node_groups).empty?
      'remove'
    elsif user_data['action'].nil?
      'create'
    else
      user_data['action']
    end

  ruby_block "get_user_info_#{username}" do
    block do
      user_account = WMI::Win32_UserAccount.find(:all, conditions: { localaccount: 'TRUE', name: username })
      if user_account && user_account.any?
        node.override['system_users']['sid'] = user_account.first.attributes.fetch('sid')
      else
        node.override['system_users']['sid'] = nil
      end
      user_profile = WMI::Win32_UserProfile.find(:all, conditions: { sid: node['system_users']['sid'] })
      if user_profile && user_profile.any?
        profile_path = user_profile.first.attributes.fetch('local_path')
        node.override['system_users']['user_password'] = nil
      else
        profile_path = nil
        node.override['system_users']['user_password'] = Sysrandom.base64(45)
      end
      node.override['system_users']['profile_path'] = profile_path
    end
    action :run
  end

  if user_data['action'] == 'create'
    user username do
      password lazy { node['system_users']['user_password'] unless node['system_users']['user_password'].nil? }
      notifies :run, "ruby_block[get_user_info_#{username}]", :before
    end

    powershell_script "create_userprofile_#{username}" do
      code lazy {
        <<-EOH
        $username = "$env:COMPUTERNAME\\#{username}"
        $spw = ConvertTo-SecureString "#{node['system_users']['user_password']}" -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PsCredential ($username,$spw)
        Start-Process cmd /c -Credential $cred -LoadUserProfile -NoNewWindow -Wait
      EOH
      }
      sensitive true
      timeout 60
      not_if { node['system_users']['user_password'].nil? }
    end

    if user_data.key?('ssh_keys')
      directory "#{username}_ssh" do
        path lazy { "#{node['system_users']['profile_path']}\\.ssh" }
        notifies :run, "ruby_block[get_user_info_#{username}]", :before
      end

      file "#{username}_authorized_keys" do
        path lazy { "#{node['system_users']['profile_path']}\\.ssh\\authorized_keys" }
        content user_data['ssh_keys'].first.encode('ASCII')
        sensitive true
      end
    end

    user_groups = user_data['groups'] || []
    user_groups.each do |groupname|
      if WMI::Win32_Group.find(:all, conditions: { domain: ENV['COMPUTERNAME'], name: groupname }).any?
        groups[groupname] = [] unless groups[groupname]
        groups[groupname] += [username]
      end
    end
  end

  if user_data['action'] == 'remove'
    powershell_script "delete_userprofile_#{username}" do
      code lazy {
      <<-EOH
        (Get-WmiObject Win32_UserProfile -Filter "SID='#{node['system_users']['sid']}'").delete()
      EOH
      }
      not_if { node['system_users']['sid'].nil? }
      notifies :run, "ruby_block[get_user_info_#{username}]", :before
    end

    user username do
      action :remove
    end
  end
end

groups['Administrators'] = [] unless groups['Administrators']
groups['Administrators'] += ['Administrator']

groups.each do |groupname, membership|
  group groupname do
    members membership
    append true
  end
end
