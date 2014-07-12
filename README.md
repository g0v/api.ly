api.ly
======

api.ly.g0v.tw endpoint source and utility scripts

# Development

*   Ubuntu 14.04 (LTS) / Mint 17 (LTS)

    Web server (api endpoint)

    1.  Install docker

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

            $ ./docker/build-image.sh

    3.  Run postgres

            $ ./docker/postgres.sh

    4.  Run api.ly

            $ ./docker/app.sh

        Open you browser, see http://127.0.0.1:3000/collections/sittings

    Wokers

    *   Run calendar worker/crawler

            $ ./docker/worker-calendar.sh

    *   Run sitting worker/crawler

            $ ./docker/worker-sitting.sh

    *   Run motion & bill worker/crawler

            $ ./docker/worker-motion-and-bill.sh

    *   Run bill-details worker/crawler

            $ ./docker/worker-bill-details.sh

    Dig into database (postgres)

        $ ./docker/psql.sh
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
