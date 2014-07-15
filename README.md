api.ly
======

api.ly.g0v.tw endpoint source and utility scripts

# Development

*   Linux

    We **recommend** using docker for developing. Docker will install all the packages, configurations, database needed in a image (a file), not in your computer.

    Web server (api endpoint)

    1.  Install docker (eg. ubuntu 14.04)

            $ sudo apt-get update
            $ sudo apt-get install docker.io apparmor-utils
            $ sudo ln -sf /usr/bin/docker.io /usr/local/bin/docker
            $ sudo sed -i '$acomplete -F _docker docker' /etc/bash_completion.d/docker.io

        Remove sudo

            $ sudo groupadd docker
            $ sudo gpasswd -a ${USER} docker
            $ sudo service docker.io restart

            # Please re-login

        Remove docker and local DNS server warnings

            $ sudo vim /etc/default/docker.io -c '%s/#DOCKER_OPTS/DOCKER_OPTS/ | wq'
            $ sudo service docker.io restart

    2.  Build image

            $ ./docker/scripts/build-image.sh

    3.  Run postgres

            $ ./docker/postgres.sh

    4.  Run api.ly

            $ ./docker/app.sh

        Open you browser, see http://127.0.0.1:3000/collections/sittings

    Wokers

    If you change any code of workers, please run:

        $ ./docker/scripts/build-image.sh

    *   Run calendar worker

            $ ./docker/workers/calendar.sh

    *   Run sitting worker

            $ ./docker/workers/sitting.sh

    *   Run motion & bill worker

            $ ./docker/workers/motion-and-bill.sh

    *   Run bill-details worker

            $ ./docker/workers/bill-details.sh

    Dig into database (postgres)

        $ ./docker/scripts/psql.sh
        psql (9.3.4)
        Type "help" for help.

        ly=> \d
                    List of relations
         Schema |       Name        | Type  | Owner 
        --------+-------------------+-------+-------
         public | amendments        | table | ly
         public | bills             | table | ly
         public | calendar          | table | ly
         public | ivod              | table | ly
         public | laws              | table | ly
         public | motions           | table | ly
         public | sittings          | table | ly
         public | ttsbills          | table | ly
         public | ttsinterpellation | table | ly
         public | ttsmotions        | table | ly
        (10 rows)

    Delete the image

        $ docker images
        REPOSITORY  TAG           IMAGE ID      CREATED        VIRTUAL SIZE
        api.ly      ubuntu.14.04  a254eb4d3ee2  9 minutes ago  1.253 GB
        $ docker rmi a254eb4d3ee2
        Deleted: a254eb4d3ee2...

*   Windows or Mac

    1.  Install [Virtualbox](https://www.virtualbox.org/wiki/Downloads) 4.3.x

    2.  Install [Vagrant](http://downloads.vagrantup.com/) 1.4.x

    3.  Install berkshelf:

            $ sudo gem install berkshelf

    4.  Install vagrant plugins:

            $ vagrant plugin install vagrant-berkshelf
            $ vagrant plugin install vagrant-cachier

    5.  Run

            % cd cookbooks/ly.g0v.tw/
            % vagrant up

        You should now have localhost:6988 served by pgrest within the vagrant, try to access **http://localhost:6988/v0/collections/sittings**

# Host

Besides Vagrant, of course you can run a api server in your host.

the server provides RESTFUL service by pgrest. pgrest rely on postgresql, so you should install postgresql and related components to your host.

For example, in Debian/Ubuntu

*   Create `/etc/apt/sources.list.d/pgdg.list`, add this line:

    Replace the *codename* with the actual distribution you are using.

    examples (*distribution* -> *codename*):

    Debian 7.0 -> wheezy

    Ubuntu 14.04 -> trusty

        deb http://apt.postgresql.org/pub/repos/apt/ codename-pgdg main

*   Import the repository key

        $ wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
        $ sudo apt-get update

*   Install the packages.

        $ sudo apt-get install postgresql-9.3
        $ sudo apt-get install skytools3 skytools3-ticker postgresql-9.3-pgq3  # for pgq
        $ sudo apt-get install postgresql-9.3-plv8  # for plv8 extension

*   Preparation

        $ sudo su postgres
        $ export PLV8XDB=ly

## init

    % npm i

Then refer to the cookbook to initialize your postgresql.

Bootstrap with the initial dump file:

    % createdb ly
    % psql ly -c 'create extension plv8'
    % lsc app.ls --db ly --boot
    % curl https://dl.dropboxusercontent.com/u/30657009/ly/api.ly.bz2 | bzcat |  psql ly -f -

## run pgrest

    $ lsc app.ls tcp://ly:password@localhost/ly
    or
    $ lsc app.ls tcp://ly:password@localhost:5433/ly    # if your postgresql is running on port 5433

pgrest will bind a local port to serve

## data flow

![](./dataflow.png)

## fulltext from gazettes

(not automated yet)

## ivod clip metadata

populated with `update-ivod.sh`

## TTS data (WIP)

National Parliament Library provides a database called TTS.  to work with it you'll need to have lisproxy.psgi up and running, and install phatomjs and casperjs to use scripts/tts.coffee

    % sudo apt-get install cpanminus
    % cpanm Plack::App::Proxy
    % npm i -g bower
    % npm i -g casperjs
    % npm i -g phantomjs
    % bower install jquery

    % plackup lisproxy.psgi &

### bill and motion metadata

populated with `populate-ttsmotions.ls` and `populated-ttsbills.ls`

### interpellation

populated with `populate-ttsinter.ls`

API listing for api.ly
======================
- http://docs.twly.apiary.io/

To regenerate api, just run docgen.s then commit apiary.apib, the document will hook to apiary automatically

    cd ~/api.ly
    lsc docgen.ls
    git commit apiary.apib


License
=======
MIT: http://g0v.mit-license.org
