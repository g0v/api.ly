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

the server provides RESTFUL service by pgrest. pgrest rely on postgresql, so you should install postgresql and related components to your host.

For example, in Debian

    $ sudo aptitude install postgresql
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

## meeting agenda and proceeding

## bill details

## bill and motion metadata

## interpellation

See TTS for setting up casperjs environment.

Run:

    % casperjs scripts/tts.coffee --type=i --session=0803 --output=i0803.html

Note that you'll need to run a read-write-enabled pgrest for inserting data, so kill the app.ls above if you have it up and running.

    % env PATH=node_modules/.bin:$PATH pgrest --db ly
    % lsc node_modules/twlyparser/parse-tts.ls i0803.html | curl -i -H "Content-Type: application/json" -X POST -d @- http://127.0.0.1:3000/collections/ttsinter

Note that there's a bug with pgrest that if you are running multiple POST into a new collection (like ttsinter here), you need to restart the server after the first POST.

### Written Answers

    % env PLV8XDB=ly ./scripts/gen-wrans.ls | curl -i -H "Content-Type: application/json" -X POST -d @- http://127.0.0.1:3000/collections/wrans

### Debates

    % env PLV8XDB=ly ./scripts/gen-debates.ls | curl -i -H "Content-Type: application/json" -X POST -d @- http://127.0.0.1:3000/collections/debates

## fulltext from gazettes

## TTS data (WIP)

National Parliament Library provides a database called TTS.  to work with it you'll need to have lisproxy.psgi up and running, and install phatomjs and casperjs to use scripts/tts.coffee

    % cpanm Plack::App::Proxy
    % npm i -g bower
    % bower install jquery

    % plackup lisproxy.psgi &
    % casperjs scripts/tts.coffee --type=m --session=0803 --output=m0803.html

License
=======
MIT: http://g0v.mit-license.org
