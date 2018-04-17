# Encoding: utf-8

name 'system_users'
maintainer 'Philipp Hellmich'
maintainer_email 'philipp.hellmich@bertelsmann.de'
license 'Apache 2.0'
description 'A cookbook to manage users from a data bag'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.3.0'

supports 'centos'
supports 'ubuntu'

depends 'user'
depends 'user_shadow'
depends 'sudo'

issues_url 'https://github.com/arvatoaws/system_users/issues'
source_url 'https://github.com/arvatoaws/system_users'
