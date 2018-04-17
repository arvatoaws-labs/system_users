require 'chefspec'
require 'chefspec/berkshelf'
require_relative 'system_users_shared'

::LOG_LEVEL = ENV['CHEFSPEC_LOG_LEVEL'] ? ENV['CHEFSPEC_LOG_LEVEL'].to_sym : :fatal

def stub_commands; end

def stub_databags
  allow(Chef::EncryptedDataBagItem).to receive(:load).with('common', 'users').and_return(fixtures_databags('common', 'users'))
  allow(Chef::EncryptedDataBagItem).to receive(:load).with('staging', 'users').and_return(fixtures_databags('staging', 'users'))
end

def stub_environments(node)
  env = Chef::Environment.new
  env.name 'staging'
  allow(node).to receive(:chef_environment).and_return(env.name)
  allow(Chef::Environment).to receive(:load).and_return(env)
end

def stub_all(node)
  stub_commands
  stub_databags
  stub_environments(node)
end

def fixtures_databags(databag = nil, item = nil)
  filepath = File.join('./test/unit/spec/fixtures/databags/', databag, "#{item}.json")
  JSON.parse(File.read(filepath))
end

at_exit { ChefSpec::Coverage.report! }
