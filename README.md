# system_users

A cookbook to manage users from an encrypted data bag.

## Supported Platforms

* Centos 6
* Centos 7
* Ubuntu 12.04
* Ubuntu 14.04
* Ubuntu 16.04
* Ubuntu 18.04

## Dependencies

* https://supermarket.chef.io/cookbooks/user
* https://supermarket.chef.io/cookbooks/user_shadow
* https://supermarket.chef.io/cookbooks/sudo

Upstream dependencies are pinned to good known versions.

## Attributes

* `node['system_users']['data_bag']` : Which data bag contains the item with user records. Defaults to `common`
* `node['system_users']['data_bag_item']` : The item that holds the user records. Defaults to `users`
* `node['system_users']['node_groups']` : An array of strings representing membership groups declared by the node calling the recipe. These are used to create users and grant sudo to them only on specific nodes. Defaults to `[]` (empty array).

## Usage
The recipe reads the users from an *encrypted* data bag item. By default, looks for a data bag named `common` and an item called `users`. This can be overwritten in the consuming cookbook.
After you define the users in the data bag, place a dependency on the system_users cookbook in your cookbook's metadata.rb:
```
depends 'system_users'
```
Then, in your recipe
```
include_recipe 'system_users'
```
if you have unit tests in your consuming cookbook then you will also likely need to add the `ruby-shadow` gem to your `Gemfile`, something like this:

```
source 'https://rubygems.org'

group :unit do
  gem 'berkshelf'
  gem 'chefspec'
  gem 'ruby-shadow'
end
```

### In scope
 * Handles user creation, removal, modification and ssh keys. Leverages the `user_account` resource https://supermarket.chef.io/cookbooks/user
 * Handles account/password expiry information. Leverages the `user_shadow` resource https://supermarket.chef.io/cookbooks/user_shadow
 * Handles a basic sudo entry for each user. Leverages the `sudo` resource https://supermarket.chef.io/cookbooks/sudo
 * Handles Linux group membership for users
 * Provides a membership method for adding users and grant sudo only on specific nodes

### Overview
The recipe logic is driven by user records in the data bag. Data bag name defaults to `common` and the item name to `users` but they can be overwritten.
An example of a `users` data bag item:

```
{
  "id": "users",
  "testuser": {
  },
  "newuser1": {
    "sudo": {

    }
  },
  "newuser2": {
    "comment": "another new user",
    "uid": 2000,
    "gid": 2000,
    "shell": "/bin/dash",
    "home": "/home/custom_home_directory",
    "password": "$6$bLZbaeySMzRx7P29$cmmF4SbtnXe2Gc1cBc0fpnBUEPxrr8inn6SNq9xpcT7M/vM0FpZmGF105LWrGCValjJMqEtBALZOYayppwJAj/",
    "ssh_keygen": true,
    "ssh_keys": [
      "key1",
      "key2"
    ],
    "groups": [
      "newgroup2"
    ],
    "sp_lstchg": "2015-07-30",
    "sp_expire": "2035-09-30",
    "sp_min": 30,
    "sp_max": 60,
    "sp_inact": 5,
    "sp_warn": 5,
    "sudo": {
      "nopasswd": true,
      "commands": [
        "/etc/init.d/httpd restart",
        "/sbin/iptables"
      ],
      "defaults": [
        "!requiretty",
        "env_reset"
      ]
    }
  },
  "olduser": {
    "action": "remove"
  }
}
```

#### Adding users with basic configuration (no password expiry info, no sudo)
The basic attribues of a user are named exactly as the parameters used by the `user_account` resource and can be added or omitted completely in which case default values are used. In fact users can be added by simply adding records like:

```
{
  "id": "users",
  "user1": {},
  "user2": {},
  "user3": {}
}
```

Here is an example with some basic attributes:

```
{
  "id": "users",
  "newuser": {
    "comment": "another new user",
    "uid": 2000,
    "gid": 2000,
    "shell": "/bin/dash",
    "home": "/home/custom_home_directory",
    "password": "$6$bLZbaeySMzRx7P29$cmmF4SbtnXe2Gc1cBc0fpnBUEPxrr8inn6SNq9xpcT7M/vM0FpZmGF105LWrGCValjJMqEtBALZOYayppwJAj/",
    "ssh_keygen": true,
    "ssh_keys": [
      "key1",
      "key2"
    ],
    "groups": [
      "newgroup2"
    ]
  }
}
```

The above example also shows the usage of the `groups` array which is a list of Linux groups that the user will be granted membership. The group will be created if doesn't exist.

#### Adding a user with password/account expiry information
Password/account expiry information is set by adding attributes in the data bag named exactly as the parameters used by the `user_shadow` resource. Example:

```
{
  "id": "users",
  "newuser": {
    "sp_lstchg": "2015-07-30",
    "sp_expire": "2035-09-30",
    "sp_min": 30,
    "sp_max": 60,
    "sp_inact": 5,
    "sp_warn": 5
  }
}
```

#### Creating users only on specific servers
User creation on nodes can be controlled by declaring a list of groups on the node consuming the recipe and then subscribing the user to at least one of those groups in the data bag. The user will be created on the node if the user subscribes to at least one of the groups the node declares or if the user doesn't define them at all. Groups declaration on the node can be done in the consuming recipe, for example:


```
node.default['system_users']['node_groups'] = ['web', 'admin', 'test']

include_recipe 'system_users'
```


And then on the data bag the user can subscribe to one of the groups like:


```
{
  "id": "users",
  "newuser": {
    "node_groups": ["admin"]
  }
}
```

The recipe also creates Linux groups named after the `node_groups` that the user subscribes to *and* are also found in the node_groups list that the node declares. In the case above, the `admin` group will be created and the `newuser` will be granted membership on it. These Linux groups can be used in the future to grant privileges only to members of that groups if desired.

It is worth emphasizing that this membership mechanism is an optional feature: if the node and user don't use it then the user will simply be created on all nodes consuming the recipe.

More complex membership requirements can be handled by approprieatly naming the `node_groups` items. Here are some scenarios and how they can be implemented using this mechanism:

##### User must be on all servers regardless of role or environment:

```
node_groups should not be defined for the user
```

##### User must be on all servers on environment `X`:
On any node consuming `system_users`:

```
node.default['system_users']['node_groups'] = [ node.chef_environment ]
```

On the `users` data bag item:

```
"user": {
  "node_groups": [ "X" ]
}
```

##### User must be on all servers running role `X` on *any* environment:
On the node with role `X`:

```
node.default['system_users']['node_groups'] = [ 'X' ]
```

On the `users` data bag item:

```
"user": {
  "node_groups": [ "X" ]
}
```

##### User must be on all servers running role `X` *or* role `Y` on *any* environment:
On the node with role `X`:

```
node.default['system_users']['node_groups'] = [ 'X' ]
```

On the node with role `Y`:

```
node.default['system_users']['node_groups'] = [ 'Y' ]
```

On the `users` data bag item:

```
"user": {
  "node_groups": [ "X" , "Y" ]
}
```

##### User must be on all servers running role `X` *only* on environment `Y`:
On the node with role `X`:

```
node.default['system_users'] = [ "X_#{node.chef_environment}" ]
```

On the `users` data bag item:

```
"user": {
  "node_groups": [ "X_Y" ]
}
```

##### User must be on all servers running role `X` *or* role `Y` *only* on environment `Z`:
On the node with role `X`:

```
node.default['system_users']['node_groups'] = [ "X_#{node.chef_environment}" ]
```

On the node with role `Y`:

```
node.default['system_users']['node_groups'] = [ "Y_#{node.chef_environment}" ]
```

On the `users` data bag item:

```
"user": {
  "node_groups": [ "X_Z" , "Y_Z" ]
}
```

##### User must be on all servers running role `X` *only* on environment `Y` and servers running role `Z` but *only* on environment `K`:
On the node with role `X`:

```
node.default['system_users']['node_groups'] = [ "X_#{node.chef_environment}" ]
```

On the node with role `Z`:

```
node.default['system_users']['node_groups'] = [ "Z_#{node.chef_environment}" ]
```

On the `users` data bag item:

```
"user": {
  "node_groups": [ "X_Y" , "Z_K" ]
}
```

Other scenarios can be potentially handled by having some logic in the recipe that creates/defines the string to be used in the `node['system_users']['node_groups']` attribute. For instance if one wanted to create a user only on nodes with more than 2 CPU cores (because of some strange requirement) then they could potentially do something like this:

On any node consuming `system_users`:

```
if node['cpu']['total'] > 2
  membership_based_on_number_of_cores = 'cores_greater_than_2'
end

node.default['system_users']['node_groups'] = [ membership_based_on_number_of_cores ]
```

On the `users` data bag item:

```
"user": {
  "node_groups": [ "cores_greater_than_2" ]
}
```

#### Sudo

A basic sudo entry can be created by adding an empty `sudo` section:

```
{
  "id": "users",
  "newuser": {
    "sudo": {}
  }
}
```

This will add a `/etc/sudoers.d/newuser` file with privileges allowing the user to execute any command as `ALL` by entering their password (the default of the sudo resource). The user will have to enter their password. The recipe uses the `sudo` resource and some features of that can be overwritten, namely `nopasswd`, `commands`, `runas` and `defaults`. For example:

```
{
  "id": "users",
  "newuser": {
    "sudo": {
      "nopasswd": true,
      "commands": [
        "/etc/init.d/httpd restart",
        "/sbin/iptables"
      ],
      "defaults": [
        "!requiretty",
        "env_reset"
      ]
    }
  }
}
```

If there is no `sudo` section, a sudo entry will not be added for that user. Sudo creation can be controlled even further by again using the `node_groups` mechanism. If the `sudo` section has a `node_groups` sub section then that will be compared against the `node_groups` the node declares. If no common items are found then a sudo entry will not be added. For example:

```
{
  "id": "users",
  "newuser": {
    "sudo": {
      "node_groups": ["web","admin"]
    }
  }
}
```

Also note that if the user doesn't declare `node_groups` under the sudo section then it is assumed that it has sudo on all nodes.

#### Using a different data bag
You can point to a different data bag and item by overwriting the corresponding attributes in the consuming cookbook, for example:

```
# override default data bag and item
node.default['system_users']['data_bag'] = 'my_data_bag'
node.default['system_users']['data_bag_item'] = 'my_users'

include_recipe 'system_users'
```

## Contributing

1. Fork the repository on Github
2. Create a named feature branch (i.e. `add-my-feature`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request

## License and Authors

Authors:: Kostas Georgakopoulos (kostas.georgakopoulos@rackspace.co.uk), Martin Smith (martin.smith@rackspace.com), Patrick Robinson (patrick.robinson@bertelsmann.de), Stephan Telahr (stephan.telahr@bertelsmann.de), Philipp Hellmich (philipp.hellmich@bertelsmann.de), Frederik Schubert (frederik.schubert@bertelsmann.de)
