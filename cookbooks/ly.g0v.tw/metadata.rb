name             'ly.g0v.tw'
maintainer       'clkao'
maintainer_email 'clkao@clkao.org'
license          'BSD'
description      'Installs/Configures api.ly.g0v.tw endpoint'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends "runit"
depends "database"
depends "cron"
depends "libreoffice"
depends "casperjs"
depends "nginx"
