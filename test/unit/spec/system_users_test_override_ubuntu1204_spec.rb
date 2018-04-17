require_relative 'spec_helper'
require_relative 'ubuntu1204_options'

describe 'system_users_test::override on Ubuntu 12.04' do
  cached(:chef_run) do
    ChefSpec::SoloRunner.new(UBUNTU1204_SERVICE_OPTS) do |node|
      stub_all(node)
    end.converge('system_users_test::override')
  end

  it_behaves_like 'users override'
end
