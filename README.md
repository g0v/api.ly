api.ly
======

api.ly.g0v.tw endpoint source and utility scripts

# Vagrant

Vagrant provides a virtual machine that helps developers have consistent developing environment.

## Prepare

To install vagrant and berkshelf. The version of vagrant on gem is too old to run on cookbook. Get the version which provided by your package management of system. Vergrant >= 1.2.x should work.

For example, in Debian

    $ sudo aptitude install vagrant

Then install plugin for vegrant. (the plugin has been renamed from berkshelf-vagrant to vagrant-berkshelf)

    $ vagrant plugin install vagrant-berkshelf
    $ vagrant plugin install vagrant-cachier

## using vagrant for development

    % cd cookbooks/ly.g0v.tw/
    % vagrant up

    # these are now part of the cookbook, but if you want to bootstrap database manually:
    % vagrant ssh
    vagrant % sudo su postgres -c "psql ly -c 'create extension plv8'"
    vagrant % curl https://dl.dropboxusercontent.com/u/30657009/ly/api.ly.bz2 | bzcat |  psql postgresql://ly:password@localhost/ly

You should now have localhost:6987 served by pgrest within the vagrant

# Host

Besides Vagrant, of course you can run a api server in your host.

## init

    % npm i

Then refer to the cookbook to initialize your postgresql.

Bootstrap with the initial dump file:

    % createdb ly
    % curl https://dl.dropboxusercontent.com/u/30657009/ly/api.ly.bz2 | bzcat |  psql ly -f -

## run pgrest

    $ lsc app.ls tcp://ly:password@localhost/ly
    or
    $ lsc app.ls tcp://ly:password@localhost:5433/ly    # if your postgresql is running on port 5433

pgrest will bind a local port to serve

## calendar

    % DB=ly lsc populate-calendar.ls  --year 2013

## meeting agenda and proceeding

## bill details

## bill and motion metadata

## interpellation

## fulltext from gazettes

## TTS data (WIP)

National Parliament Library provides a database called TTS.  to work with it you'll need to have lisproxy.psgi up and running, and install phatomjs and casperjs to use scripts/tts.coffee

    % npm i -g bower
    % bower install jquery
    % casperjs scripts/tts.coffee

License
=======
MIT: http://g0v.mit-license.org
