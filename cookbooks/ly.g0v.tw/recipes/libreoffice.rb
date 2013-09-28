include_recipe "libreoffice::unoconv"

major_version = '4'
minor_version = '1'

apt_repository "libreoffice-#{major_version}.#{minor_version}" do
  uri "http://ppa.launchpad.net/libreoffice/libreoffice-#{major_version}-#{minor_version}/ubuntu"
  distribution node['lsb']['codename']
  components ["main"]
  keyserver "keyserver.ubuntu.com"
  key "1378B444"
end


packages = %w{libreoffice-writer lp-solve python-uno libreoffice-script-provider-python}
packages.each do |p|
  package p do
    action :upgrade
  end
end
