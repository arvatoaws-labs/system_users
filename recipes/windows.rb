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

  if user_data['action'] == 'create'
    user_password = Sysrandom.base64(45) unless ::File.directory?("C:\\Users\\#{username}")
    user username do
      password user_password if user_password
    end

    powershell_script "create_userprofile_#{username}" do
      code <<-EOH
        $username = "$env:COMPUTERNAME\\#{username}"
        $spw = ConvertTo-SecureString "#{user_password}" -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PsCredential ($username,$spw)
        Start-Process cmd /c -Credential $cred -LoadUserProfile -NoNewWindow -Wait
      EOH
      sensitive true
      timeout 60
      not_if { ::File.directory?("C:\\Users\\#{username}") }
    end

    if user_data.key?('ssh_keys')
      directory "C:\\Users\\#{username}\\.ssh"

      file "C:\\Users\\#{username}\\.ssh\\authorized_keys" do
        content user_data['ssh_keys'].first.encode('ASCII')
        sensitive true
      end
    end

    user_groups = user_data['groups'] || []
    user_groups.each do |groupname|
      if WMI::Win32_Group.find(:all, conditions: { name: groupname }).any?
        groups[groupname] = [] unless groups[groupname]
        groups[groupname] += [username]
      end
    end
  end

  if user_data['action'] == 'remove'
    user_account = WMI::Win32_UserAccount.find(:all, conditions: { localaccount: 'TRUE', name: username })
    sid = user_account.first.attributes.fetch('sid') unless user_account.empty?

    powershell_script "delete_userprofile_#{username}" do
      code <<-EOH
        (Get-WmiObject Win32_UserProfile -Filter "SID='#{sid}'").delete()
      EOH
      not_if { WMI::Win32_UserProfile.find(:all, conditions: { sid: sid }).empty? }
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
