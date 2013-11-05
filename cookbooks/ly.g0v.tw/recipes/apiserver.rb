include_recipe "runit"
include_recipe "database"
include_recipe "cron"
include_recipe "postgresql::ruby"
include_recipe "ly.g0v.tw::nginx"
include_recipe "ly.g0v.tw::apilib"

postgresql_connection_info = {:host => "127.0.0.1",
                              :port => node['postgresql']['config']['port'],
                              :username => 'postgres',
                              :password => node['postgresql']['password']['postgres']}

database 'ly' do
  connection postgresql_connection_info
  provider Chef::Provider::Database::Postgresql
  action :create
end

db_user = postgresql_database_user 'ly' do
  connection postgresql_connection_info
  database_name 'ly'
  password 'password'
  privileges [:all]
  action :create
end

postgresql_database "grant schema" do
  connection postgresql_connection_info
  database_name 'ly'
  sql "grant CREATE on database ly to ly"
  action :nothing
  subscribes :query, resources(:postgresql_database_user => 'ly'), :immediately
end

connection_info = postgresql_connection_info.clone()
connection_info[:username] = 'ly'
connection_info[:password] = 'password'
conn = "postgres://#{connection_info[:username]}:#{connection_info[:password]}@#{connection_info[:host]}/ly"

# XXX: use whitelist
postgresql_database "plv8" do
  connection postgresql_connection_info
  database_name 'ly'
  sql "create extension plv8"
  action :nothing
  subscribes :query, resources(:postgresql_database_user => 'ly'), :immediately
end

execute "boot api.ly" do
  cwd "/opt/ly/api.ly"
  action :nothing
  user "nobody"
  command "lsc app.ls --db #{conn} --boot"
  subscribes :run, "execute[install api.ly]", :immediately
end

# XXX: ensure londiste is not enabled yet
bash 'init db' do
  code <<-EOH
    curl https://dl.dropboxusercontent.com/u/30657009/ly/api.ly.bz2 | bzcat | psql #{conn}
  EOH
  action :nothing
  subscribes :run, resources(:postgresql_database_user => 'ly')
end

runit_service "lyapi" do
  default_logger true
  action [:enable, :start]
  subscribes :restart, "execute[install api.ly]"
end

template "/etc/nginx/sites-available/lyapi" do
  source "site-lyapi.erb"
  owner "root"
  group "root"
  variables {}
  mode 00755
end
nginx_site "lyapi"

cron "populate-calendar" do
  minute "30"
  mailto "clkao@clkao.org"
  action :create
  user "nobody"
  command "cd /opt/ly/api.ly && lsc populate-calendar --db #{conn}"
end

template "/opt/ly/update-video.sh" do
  source "update-video.erb"
  owner "root"
  group "root"
  variables ({:conn => conn})
  mode 00755
end

cron "populate-video" do
  minute "50"
  hour "13,19"
  mailto "clkao@clkao.org"
  action :create
  user "nobody"
  command "/opt/ly/update-video.sh"
end

# pgqd

package "skytools3"
package "skytools3-ticker"
package "postgresql-9.2-pgq3"

directory "/var/log/postgresql" do
  owner "postgres"
  group "postgres"
end

template "/opt/ly/londiste.ini" do
  source "londiste.erb"
  owner "root"
  group "root"
  variables {}
  mode 00644
end

template "/opt/ly/pgq.ini" do
  source "pgq.erb"
  owner "root"
  group "root"
  variables {}
  mode 00644
end

execute "init londiste" do
  command "londiste3 /opt/ly/londiste.ini create-root apily 'dbname=ly'"
  user "postgres"
end

execute "init pgq" do
  command "londiste3 /opt/ly/londiste.ini add-table calendar sittings bills"
  user "postgres"
end

runit_service "pgqd" do
  default_logger true
  action [:enable, :start]
end

if node[:ly][:firebase]
  runit_service "live-firebase" do
    default_logger true
    action [:enable, :start]
    env ({
      "FIREBASE" => node[:ly][:firebase],
      "FIREBASE_SECRET" => node[:ly][:firebase_secret]
    })
  end
end
