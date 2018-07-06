name 'system_users'
maintainer 'Philipp Hellmich'
maintainer_email 'philipp.hellmich@bertelsmann.de'
license 'Apache-2.0'
description 'A cookbook to manage users from a data bag'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
chef_version '>= 12'
version '0.3.3'

supports 'centos'
supports 'ubuntu'
supports 'windows'

depends 'user'
depends 'sudo'

issues_url 'https://github.com/arvatoaws/system_users/issues'
source_url 'https://github.com/arvatoaws/system_users'
