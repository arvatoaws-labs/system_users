source 'https://rubygems.org'

group :lint do
  gem 'cookstyle'
  gem 'foodcritic', '~> 6.0'
end

group :unit do
  gem 'berkshelf', '~> 5.0'
  gem 'chef-sugar'
  gem 'chefspec'
  gem 'inspec'
  gem 'ruby-shadow'
end

group :kitchen_common do
  gem 'test-kitchen'
end

group :kitchen_vagrant do
  gem 'kitchen-ec2'
  gem 'kitchen-inspec'
  gem 'kitchen-vagrant'
  gem 'vagrant-wrapper'
end

group :kitchen_rackspace do
  gem 'kitchen-rackspace'
end

group :development do
  gem 'growl'
  gem 'guard'
  gem 'guard-foodcritic'
  gem 'guard-kitchen'
  gem 'guard-rubocop'
  gem 'rb-fsevent'
  gem 'stove', '= 3.2.5'
end

group :vulnerable_versions do
  gem 'minitar', '~> 0.6'
  gem 'yajl-ruby', '>= 1.3.1'
end
