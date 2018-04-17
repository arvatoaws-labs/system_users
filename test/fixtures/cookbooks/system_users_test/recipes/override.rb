
# override default data bag and item
node.default['system_users']['data_bag'] = node.chef_environment
node.default['system_users']['data_bag_item'] = 'users'

# declare node tags
node.default['system_users']['node_groups'] = [node.chef_environment, 'web', 'marketing', 'sales']

# Create a user manualy. The recipe should delete the user afterwards.
user_account 'olduser'

sudo 'olduser' do
  user 'olduser'
  runas 'root'
  nopasswd true
end

include_recipe 'system_users'
