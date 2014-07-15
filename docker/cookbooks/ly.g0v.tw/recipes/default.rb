include_recipe 'postgresql'

package 'nodejs' 
package 'npm' 
package 'git'
package 'curl'
package 'postgresql-9.3'
package 'postgresql-server-dev-9.3'
package 'skytools3'        # pgq
package 'skytools3-ticker' # pgq daemon (a simple ticker)
package 'postgresql-9.3-pgq3'
package 'postgresql-9.3-plv8'  # for plv8 extension

execute 'install nodejs' do
  command 'ln -s /usr/bin/nodejs /usr/bin/node'
end

execute 'install LiveScript' do
  command 'npm i -g LiveScript'
end

execute 'install api.ly' do
  cwd '/app'
  command 'npm i'
end

execute 'run postgres' do
  command 'service postgresql start'
end

pg_user 'ly' do
  privileges superuser: false, createdb: true, login: true
  password 'ly'
end

pg_database 'ly' do
  owner 'ly'
  encoding 'utf8'
  template 'template0'
end

pg_database_extensions 'ly' do
  extensions ['plv8']
end

execute 'boot api.ly' do
  cwd '/app'
  command 'lsc app.ls --db tcp://ly:ly@localhost/ly --boot'
end

execute 'init db' do
  command <<-EOF
    export PGPASSWORD=ly && \
    curl https://dl.dropboxusercontent.com/u/30657009/ly/api.ly.bz2 | bzcat | psql -U ly -h localhost -f -
  EOF
end

directory '/opt/ly' do
  action :create
end

template '/opt/ly/londiste.ini' do
  source 'londiste.erb'
  owner 'root'
  group 'root'
  variables {}
  mode 00644
end

template '/opt/ly/pgq.ini' do
  source 'pgq.erb'
  owner 'root'
  group 'root'
  variables {}
  mode 00644
end

directory '/var/log/postgresql' do
  owner 'postgres'
  group 'postgres'
end

execute 'init londiste' do
  user 'postgres'
  command 'londiste3 /opt/ly/londiste.ini create-root apily "dbname=ly"'
end

execute 'init pgq' do
  user 'postgres'
  command 'londiste3 /opt/ly/londiste.ini add-table calendar sittings bills'
end

execute 'configure postgres' do
  command <<-EOF
    echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/9.3/main/pg_hba.conf &&\
    echo "listen_addresses='*'" >> /etc/postgresql/9.3/main/postgresql.conf
  EOF
end
