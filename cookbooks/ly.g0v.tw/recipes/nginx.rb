git "/opt/nginx-rtmp-module" do
  repository "git://github.com/arut/nginx-rtmp-module"
  reference "v1.0.6"
  action :sync
end

include_recipe "nginx::source"
