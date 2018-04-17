# Set default values for data bag and item containing users.
# These can be overriden in the consuming cookbook.
default['system_users']['data_bag'] = 'common'
default['system_users']['data_bag_item'] = 'users'

# The node_groups attribute can be used to create users on specific nodes.
# By default we don't declare any node_groups.
# This can be overriden in the consuming cookbook.
default['system_users']['node_groups'] = []
