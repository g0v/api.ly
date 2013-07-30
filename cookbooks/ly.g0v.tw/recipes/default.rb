directory "/opt/ly" do
  action :create
end

git "/opt/ly/twlyparser" do
  repository "git://github.com/g0v/twlyparser.git"
  reference "master"
  action :sync
end

execute "install twlyparser" do
  action :nothing
  subscribes :run, resources(:git => "/opt/ly/twlyparser")
  command "npm i && npm link"
end

# XXX: when used with vagrant, use /vagrant_git as source
git "/opt/ly/api.ly" do
  repository "git://github.com/g0v/api.ly.git"
  reference "master"
  action :sync
end

execute "install api.ly" do
  action :nothing
  subscribes :run, resources(:git => "/opt/ly/api.ly")
  command "npm link twlyparser && npm i"
end

runit_service "lyapi" do
  default_logger true
end

