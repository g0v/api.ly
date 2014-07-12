FROM ubuntu:14.04
MAINTAINER Lien Chiang <xsoameix@gmail.com>

# Install postgres

RUN apt-get update
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get install -y wget sysv-rc
RUN cd /etc/apt/sources.list.d && echo 'deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main' > pgdg.list

# Import the repository key
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
RUN apt-get update

# Install the packages.
RUN apt-get install -y postgresql-9.3 postgresql-server-dev-9.3
RUN apt-get install -y skytools3 skytools3-ticker postgresql-9.3-pgq3  # for pgq
RUN apt-get install -y postgresql-9.3-plv8  # for plv8 extension

# Init api.ly
RUN apt-get install -y nodejs npm git curl
RUN ln -s /usr/bin/nodejs /usr/bin/node 
RUN npm install -g LiveScript

# Install packages using by api.ly
ADD package.json /tmp/package.json
RUN cd tmp && npm i
RUN mkdir app && cp -a /tmp/node_modules app

USER postgres
RUN service postgresql start && \
    psql postgres -c "create user ly with createdb password 'ly';" && \
    createdb -O ly ly && \
    psql ly -c "create extension plv8;"
ADD app.ls app/app.ls
ADD package.json app/package.json
ADD lib app/lib
ADD cookbooks/ly.g0v.tw/templates/default/londiste.erb /opt/ly/londiste.ini
RUN service postgresql start && \
    cd /app && \
    lsc app.ls --db tcp://ly:ly@localhost/ly --boot && \
    export PGPASSWORD=ly && \
    curl https://dl.dropboxusercontent.com/u/30657009/ly/api.ly.bz2 | bzcat | psql -U ly -h localhost -f - && \
    londiste3 /opt/ly/londiste.ini create-root apily 'dbname=ly' && \
    londiste3 /opt/ly/londiste.ini add-table calendar sittings bills

# Configure postgres (database server)
RUN echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/9.3/main/pg_hba.conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.3/main/postgresql.conf

# Configure pgqd (pgq deamon / skytools3-ticker)
ADD cookbooks/ly.g0v.tw/templates/default/pgq.erb /opt/ly/pgq.ini
