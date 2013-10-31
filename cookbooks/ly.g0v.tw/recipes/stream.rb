
package "pkg-config"
package "yasm"
package "libvorbis-dev"
package "libvpx-dev"
package "libx264-dev"

git "/opt/ffmpeg" do
  repository "git://github.com/FFmpeg/FFmpeg"
  reference "n1.2.4"
  action :sync
end

execute "install ffmpeg" do
  cwd "/opt/ffmpeg"
  action :nothing
  subscribes :run, resources(:git => "/opt/ffmpeg"), :immediately
  command "./configure --enable-libvpx --enable-libvorbis --enable-libx264 && make"
end

git "/opt/msdl" do
  repository "git://github.com/clkao/msdl"
  reference "master"
  action :sync
end

execute "install msdl" do
  cwd "/opt/msdl"
  action :nothing
  subscribes :run, resources(:git => "/opt/msdl"), :immediately
  command "./configure && make"
end

template "/etc/nginx/rtmp.conf" do
  source "rtmp.erb"
  owner "root"
  group "root"
  variables {}
  mode 00755
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
  variables {}
  mode 00755
end

runit_service "ffserver" do
  default_logger true
  action [:enable, :start]
end