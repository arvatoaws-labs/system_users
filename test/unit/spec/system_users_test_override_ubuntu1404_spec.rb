require_relative 'spec_helper'
require_relative 'ubuntu1404_options'

describe 'system_users_test::override on Ubuntu 14.04' do
  cached(:chef_run) do
    ChefSpec::SoloRunner.new(UBUNTU1404_SERVICE_OPTS) do |node|
      stub_all(node)
    end.converge('system_users_test::override')
  end

  it_behaves_like 'users override'
end
