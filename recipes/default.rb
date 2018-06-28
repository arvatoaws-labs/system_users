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

if node['platform'].include?('windows')
  include_recipe 'system_users::windows'
else
  include_recipe 'system_users::linux'
end
