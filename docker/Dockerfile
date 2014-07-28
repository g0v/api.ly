FROM phusion/baseimage:0.9.11
MAINTAINER Lien Chiang <xsoameix@gmail.com>

# Install berkshelf
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get update -y
RUN apt-get install -y curl libxml2-dev libxslt-dev git \
                       autoconf automake build-essential
RUN curl -L https://www.opscode.com/chef/install.sh | bash
RUN echo "gem: --no-ri --no-rdoc" > ~/.gemrc
RUN /opt/chef/embedded/bin/gem install berkshelf

# app.ls
ADD package.json /app/package.json
ADD app.ls /app/app.ls
ADD lib /app/lib

# Use cookbooks
ADD docker/cookbooks/ly.g0v.tw /chef
RUN cd /chef && /opt/chef/embedded/bin/berks vendor cookbooks
RUN chef-solo -c /chef/solo.rb -j /chef/solo.json

# workers
ADD populate-calendar.ls /app/populate-calendar.ls
ADD calendar-sitting.ls /app/calendar-sitting.ls
ADD ys-misq.ls /app/ys-misq.ls
ADD bill-details.ls /app/bill-details.ls
