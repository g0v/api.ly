api.ly
======

api.ly.g0v.tw endpoint source and utility scripts

## using vagrant for development

    # install vagrant, berkshelf
    % cd cookbooks/ly.g0v.tw/
    % vagrant up

    # these should be part of the cookbook, but you'll need to do these manually for now:
    % vagrant ssh
    vagrant % sudo su postgres -c "psql ly -c 'create extension plv8'"
    vagrant % curl https://dl.dropboxusercontent.com/u/30657009/ly/api.ly.bz2 | bzcat |  psql postgresql://ly:password@localhost/ly

You should now have localhost:6987 served by pgrest within the vagrant

## init

    % npm i

Bootstrap with the initial dump file:

    % createdb ly
    % curl https://dl.dropboxusercontent.com/u/30657009/ly/api.ly.bz2 | bzcat |  psql ly -f -

## calendar

    % DB=ly lsc populate-calendar.ls  --year 2013

## meeting agenda and proceeding

## bill details

## bill and motion metadata

## interpellation

## fulltext from gazettes

License
=======
MIT: http://g0v.mit-license.org
