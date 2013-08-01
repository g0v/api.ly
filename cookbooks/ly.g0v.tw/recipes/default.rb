include_recipe "runit"

directory "/opt/ly" do
  action :create
end

git "/opt/ly/twlyparser" do
  repository "git://github.com/g0v/twlyparser.git"
  reference "master"
  action :sync
end

execute "install LiveScript" do
  command "npm i -g LiveScript@1.1.1"
  not_if "test -e /usr/bin/lsc"
end

execute "install twlyparser" do
  cwd "/opt/ly/twlyparser"
  action :nothing
  subscribes :run, resources(:git => "/opt/ly/twlyparser")
  command "npm i && sudo npm link"
end

# XXX: when used with vagrant, use /vagrant_git as source
git "/opt/ly/api.ly" do
  repository "git://github.com/g0v/api.ly.git"
  reference "master"
  action :sync
end

execute "install api.ly" do
  cwd "/opt/ly/api.ly"
  action :nothing
  subscribes :run, resources(:git => "/opt/ly/api.ly")
  command "sudo npm link twlyparser pgrest && npm i && npm run prepublish"
  notifies :restart, "service[lyapi]", :immediately
end

runit_service "lyapi" do
  default_logger true
  action :enable
end

