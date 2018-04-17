#
# Cookbook Name:: system_users
# Recipe:: default
#
# Copyright (C) 2015 Rackspace
#
# All rights reserved - Do Not Redistribute
#
# This recipe creates/modifies users that are read from an encrypted data bag.
# It also handles group membership and sudo access for these users.
# The data bag and item are defined in corresponding attributes.
# Please read the README file for details.

users = Chef::EncryptedDataBagItem.load(
  node['system_users']['data_bag'],
  node['system_users']['data_bag_item']
).to_hash.reject { |user, user_data| user == 'id' }

node_groups = node['system_users']['node_groups']

groups = {}

users.each do |username, user_data|
  ## The action (if defined in the data bag) should be overwritten to 'remove' if the user's node_groups and node's node_groups don't intersect.
  ## If the user doesn't declare any node_groups then it is assumed that is present on all nodes.
  user_data['action'] = 'remove' if user_data['node_groups'] && (user_data['node_groups'] & node_groups).empty?

  # ACCOUNT
  user_account username do
    manage_home user_data['manage_home'] || true
    shell user_data['shell'] || '/bin/bash'
    %w[comment uid gid home password system_user create_group ssh_keys ssh_keygen non_unique action].each do |param|
      send(param, user_data[param]) if user_data[param]
    end
  end

  user_shadow username do
    %w[sp_lstchg sp_expire sp_min sp_max sp_inact sp_warn].each do |param|
      send(param, user_data[param]) if user_data[param]
    end
    only_if { user_data['action'] != 'remove' }
  end

  # SUDO
  ## Action will be 'remove' by default.
  sudo_action = :remove

  ## Install sudo if the user is not removed and there is a sudo entry but also take node_groups into consideration
  ## If the user doesn't declare any node_groups under the sudo section then it is assumed that it has sudo on all nodes.
  if user_data['sudo'] && user_data['action'] != 'remove'
    sudo_action = :install unless user_data['sudo']['node_groups'] && (user_data['sudo']['node_groups'] & node_groups).empty?
  end

  sudo username.delete('.') do # Filenames in /etc/sudoers.d that contain dots are ignored
    user username
    runas user_data['sudo']['runas'] if user_data['sudo'] && user_data['sudo']['runas']
    nopasswd user_data['sudo']['nopasswd'] if user_data['sudo'] && user_data['sudo']['nopasswd']
    commands user_data['sudo']['commands'] if user_data['sudo'] && user_data['sudo']['commands']
    defaults user_data['sudo']['defaults'] if user_data['sudo'] && user_data['sudo']['defaults']
    action sudo_action
  end

  # GROUPS
  ## The 'groups' in the data bag represent the OS groups that we want the user to be a member of
  user_groups = user_data['groups'] || []

  ## The final OS groups list is user_groups plus groups named after the common user & node tags
  user_node_groups = user_data['node_groups'] || []
  all_groups = user_groups | (user_node_groups & node_groups)

  next if all_groups.empty? || user_data['action'] == 'remove'

  all_groups.each do |groupname|
    groups[groupname] = [] unless groups[groupname]
    groups[groupname] += [username]
  end
end

# Group membership is re-created to ensure correct removal from group
groups.each do |groupname, membership|
  group groupname do
    members membership
    append false
  end
end
# rubocop:enable Metrics/LineLength
