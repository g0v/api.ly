include_recipe "runit"
include_recipe "database"
include_recipe "cron"
include_recipe "postgresql::ruby"

directory "/opt/ly" do
  action :create
end

git "/opt/ly/twlyparser" do
  repository "git://github.com/g0v/twlyparser.git"
  reference "master"
  action :sync
end

execute "install LiveScript" do
  command "npm i -g LiveScript@1.1.1"
  not_if "test -e /usr/bin/lsc"
end

execute "install twlyparser" do
  cwd "/opt/ly/twlyparser"
  action :nothing
  subscribes :run, resources(:git => "/opt/ly/twlyparser")
  command "npm i && npm link"
end


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

bash 'init db' do
  code <<-EOH
    curl https://dl.dropboxusercontent.com/u/30657009/ly/api.ly.bz2 | bzcat | psql #{conn}
  EOH
  action :nothing
  subscribes :run, resources(:postgresql_database_user => 'ly'), :immediately
end

# XXX: use whitelist
postgresql_database "plv8" do
  connection postgresql_connection_info
  database_name 'ly'
  sql "create extension plv8"
  action :nothing
  subscribes :query, resources(:postgresql_database_user => 'ly'), :immediately
end

# XXX: when used with vagrant, use /vagrant_git as source
git "/opt/ly/api.ly" do
  repository "git://github.com/g0v/api.ly.git"
  reference "master"
  action :sync
end

execute "install api.ly" do
  cwd "/opt/ly/api.ly"
  action :nothing
  subscribes :run, resources(:git => "/opt/ly/api.ly")
  command "npm link twlyparser pgrest && npm i && npm run prepublish"
  notifies :restart, "service[lyapi]", :immediately
end

runit_service "lyapi" do
  default_logger true
  action :enable
end

cron "populate-calendar" do
  minute "30"
  action :create
  command "cd /opt/ly/api.ly && lsc populate-calendar --yaer `date +%Y` --db #{conn}"
end
