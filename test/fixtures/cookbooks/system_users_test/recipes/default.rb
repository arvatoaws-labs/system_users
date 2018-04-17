
# Create a user manualy. The recipe should delete the user afterwards.
user_account 'olduser'

sudo 'olduser' do
  user 'olduser'
  runas 'root'
  nopasswd true
end

# Create a group - 'newuser' will be part of that group
group 'newgroup' do
  gid 2000
end

include_recipe 'system_users'
