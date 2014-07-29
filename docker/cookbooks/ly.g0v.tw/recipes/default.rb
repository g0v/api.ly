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
