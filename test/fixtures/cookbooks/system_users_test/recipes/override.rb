# override default data bag and item
node.default['system_users']['data_bag'] = node.chef_environment
node.default['system_users']['data_bag_item'] = 'users'

# declare node tags
node.default['system_users']['node_groups'] = [node.chef_environment, 'web', 'marketing', 'sales']

if node['platform'].include?('windows')
  # Create a user manualy. The recipe should delete the user afterwards.
  require 'securerandom'
  user_password = SecureRandom.base64(45)
  username = 'olduser'

  user username do
    password user_password
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
  end
else
  # Create a user manualy. The recipe should delete the user afterwards.
  user_account 'olduser'

  sudo 'olduser' do
    user 'olduser'
    runas 'root'
    nopasswd true
  end
end

include_recipe 'system_users'
