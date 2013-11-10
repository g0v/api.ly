include_recipe "ly.g0v.tw::stream-worker"

directory "/var/run/hls" do
  action :create
  owner "www-data"
  group "www-data"
end

directory "/var/run/ffserver" do
  action :create
  owner "www-data"
  group "www-data"
end

include_recipe "ly.g0v.tw::nginx"

template "/etc/nginx/rtmp.conf" do
  source "rtmp.erb"
  owner "root"
  group "root"
  variables ({
    :allow_publish => node[:ly][:allow_publish] || [],
    :rtmp_listen => node[:ly][:rtmp_listen] || '127.0.0.1',
  })
  mode 00755
  notifies :restart, "service[nginx]"
end

template "/etc/nginx/sites-available/lystream" do
  source "site-lystream.erb"
  owner "root"
  group "root"
  variables ({:fqdn => node[:ly][:lystream_fqdn]})
  mode 00755
end
nginx_site "lystream"

template "/etc/ffserver.conf" do
  source "ffserver.erb"
  owner "root"
  group "root"
  variables ({
    :channels => node[:ly][:channels],
    :max_clients => 1024,
    :max_http_connections => 2048,
    :max_bandwidth => 1024 * 1024,
  })
  mode 00755
  notifies :restart, "service[ffserver]"
end

runit_service "ffserver" do
  default_logger true
  action [:enable, :start]
end

package "ruby1.9.1"

execute "install compass" do
  command "gem install compass sass"
  only_if { ::File.exists?("/usr/local/bin/compass") }
end

git "/opt/ly/ivod.ly.g0v.tw" do
  repository "git://github.com/g0v/ivod.ly.g0v.tw.git"
  enable_submodules true
  reference "master"
  action :sync
end

link "/opt/ly/ivod" do
  to "/opt/ly/ivod.ly.g0v.tw/_public"
  action :create
end

execute "install ivod.ly.g0v.tw" do
  cwd "/opt/ly/ivod.ly.g0v.tw"
  action :nothing
  subscribes :run, resources(:git => "/opt/ly/ivod.ly.g0v.tw"), :immediately
  command "npm i && ./node_modules/.bin/brunch b -o"
end
