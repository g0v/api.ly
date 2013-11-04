include_recipe "runit"
include_recipe "database"
include_recipe "cron"

directory "/opt/ly" do
  action :create
end

directory "/opt/ly/cache" do
  action :create
  owner "nobody"
end
