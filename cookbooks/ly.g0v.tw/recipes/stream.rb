include_recipe "nginx::source"

package "pkg-config"
package "yasm"
package "libvorbis-dev"
package "libvpx-dev"
package "libx264-dev"
package "libavcodec-extra-53"
package "libmp3lame-dev"
package "libfaac-dev"

git "/opt/ffmpeg" do
  repository "git://github.com/FFmpeg/FFmpeg"
  reference "n1.0.8"
  action :sync
end

execute "install ffmpeg" do
  cwd "/opt/ffmpeg"
  action :nothing
  subscribes :run, resources(:git => "/opt/ffmpeg"), :immediately
  command "./configure --enable-libvpx --enable-libvorbis --enable-libx264 --enable-gpl --enable-nonfree --enable-libmp3lame --enable-libfaac && make"
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
  variables ({:channels => node[:ly][:channels]})
  mode 00755
  notifies :restart, "service[ffserver]"
end

runit_service "ffserver" do
  default_logger true
  action [:enable, :start]
end

node[:ly][:channels].each do |ch|
  runit_service "msdl-#{ch.channel}" do
    run_template_name "msdl"
    default_logger true
    action [:create]
    options ({
      :chid => ch.chid,
      :channel => ch.channel,
      :rtmp_server => 'rtmp://localhost:1935/hls'
    })
    service_dir "/tmp"
  end
end
