include_recipe "nodejs"
include_recipe "runit"
include_recipe "ly.g0v.tw::apilib"

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

# XXX: this should probably be in another service_dir and with custom runsvdir
# so we can do the symlinks (msdl-live.ls) without being root
node[:ly][:channels].each do |ch|
  runit_service "msdl-#{ch.channel}" do
    run_template_name "msdl"
    default_logger true
    action [:create]
    options ({
      :chid => ch.chid,
      :channel => ch.channel,
      :rtmp_server => node[:ly][:rtmp_server] || 'rtmp://localhost:1935/hls'
    })
  end
end

if node[:ly][:enable_msdl]
  cron "msdl-live" do
    minute "*/5"
    hour "0-16" # UTC
    mailto "clkao@clkao.org"
    action :create
    user "root"
    command "cd /opt/ly/api.ly && lsc msdl-live.ls"
  end
end
