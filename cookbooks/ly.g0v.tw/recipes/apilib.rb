execute "install bower" do
  command "npm i -g bower@1.2.6"
  not_if "test -e /usr/bin/bower"
end

git "/opt/ly/twlyparser" do
  repository "git://github.com/g0v/twlyparser.git"
  enable_submodules true
  reference "master"
  action :sync
end

execute "install twlyparser" do
  cwd "/opt/ly/twlyparser"
  action :nothing
  subscribes :run, resources(:git => "/opt/ly/twlyparser"), :immediately
  command "npm i && npm link"
end

# XXX: when used with vagrant, use /vagrant_git as source
git "/opt/ly/api.ly" do
  repository "git://github.com/g0v/api.ly.git"
  reference "master"
  action :sync
end

# XXX: use nobody user instead
execute "install api.ly" do
  cwd "/opt/ly/api.ly"
  action :nothing
  subscribes :run, resources(:git => "/opt/ly/api.ly"), :immediately
  command "npm link twlyparser pgrest && npm i && npm run prepublish && bower install --allow-root jquery"
end
