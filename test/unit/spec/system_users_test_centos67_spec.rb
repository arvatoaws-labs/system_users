require_relative 'spec_helper'
require_relative 'centos67_options'

describe 'system_users_test::default on Centos 6.7' do
  cached(:chef_run) do
    ChefSpec::SoloRunner.new(CENTOS67_SERVICE_OPTS) do |node|
      stub_all(node)
    end.converge('system_users_test::default')
  end

  it_behaves_like 'users'
end
