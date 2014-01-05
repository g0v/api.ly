api.ly
======

api.ly.g0v.tw endpoint source and utility scripts

# Development

We recommend using vagrant for developing

## Prepare

Install [Virtualbox](https://www.virtualbox.org/wiki/Downloads) 4.3.x

Install [Vagrant](http://downloads.vagrantup.com/) 1.4.x

Install berkshelf:

    $ sudo gem install berkshelf

Install vagrant plugins:

    $ vagrant plugin install vagrant-berkshelf
    $ vagrant plugin install vagrant-cachier

## Using Vagrant for Development

    % cd cookbooks/ly.g0v.tw/
    % vagrant up

You should now have localhost:6988 served by pgrest within the vagrant, try to access **http://localhost:6988/v0/collections/sittings**

# Host

Besides Vagrant, of course you can run a api server in your host.

the server provides RESTFUL service by pgrest. pgrest rely on postgresql, so you should install postgresql and related components to your host.

For example, in Debian

    $ sudo aptitude install postgresql
    $ sudo aptitude install skytools3 skytools3-ticker postgresql-9.2-pgq3  # for pgq
    $ sudo aptitude install postgresql-plv8  # for plv8 extension

## init

    % npm i

Then refer to the cookbook to initialize your postgresql.

Bootstrap with the initial dump file:

    % createdb ly
    % psql ly -c 'create extension plv8'
    % curl https://dl.dropboxusercontent.com/u/30657009/ly/api.ly.bz2 | bzcat |  psql ly -f -

## run pgrest

    $ lsc app.ls tcp://ly:password@localhost/ly
    or
    $ lsc app.ls tcp://ly:password@localhost:5433/ly    # if your postgresql is running on port 5433

pgrest will bind a local port to serve

## calendar

    % DB=ly lsc populate-calendar.ls  --year 2013

## sitting

populated via pgq with `calendar-sitting.ls`

## meeting agenda and proceeding

populated via pgq with `ys-misq.ls`

## bill details

populated via pgq with `bill-details.ls`

## fulltext from gazettes

(not automated yet)

## ivod clip metadata

populated with `update-ivod.sh`

## TTS data (WIP)

National Parliament Library provides a database called TTS.  to work with it you'll need to have lisproxy.psgi up and running, and install phatomjs and casperjs to use scripts/tts.coffee

    % cpanm Plack::App::Proxy
    % npm i -g bower
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
