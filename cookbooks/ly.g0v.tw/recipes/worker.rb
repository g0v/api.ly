# lisproxy
# XXX: use carton

package "cpanminus"

execute "install plack" do
  command "cpanm Plack::App::Proxy"
end

include_recipe "casperjs"
package "ruby"

runit_service "lisproxy" do
  default_logger true
  action [:enable, :start]
end

if node['twitter']
  template "/opt/ly/api.ly/twitter.json" do
    source "twitter.conf.erb"
    owner "root"
    group "root"
    variables {}
    mode 00644
  end

  # calendar-twitter
  # also tell the admin to apply a role with [:twitter] when bootstrap is ready
  # and pgq is flushed automatically somehow
  runit_service "sitting-twitter" do
    default_logger true
    action [:enable, :stop]
    subscribes :restart, "execute[install api.ly]"
  end
end

runit_service "calendar-sitting" do
  default_logger true
  action [:enable, :start]
  subscribes :restart, "execute[install api.ly]"
end

runit_service "ys-misq" do
  default_logger true
  action [:enable, :start]
  subscribes :restart, "execute[install api.ly]"
end

include_recipe "ly.g0v.tw::libreoffice"

package "libimage-size-perl"

runit_service "bill-details" do
  default_logger true
  action [:enable, :start]
  subscribes :restart, "execute[install api.ly]"
  env ({"UNOCONV_PYTHON" => "/usr/bin/python", "HOME" => "/tmp"})
end
