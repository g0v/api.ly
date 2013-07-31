api.ly
======

api.ly.g0v.tw endpoint source and utility scripts

## init

    % npm i

Bootstrap with the initial dump file:

    % createdb ly
    % curl https://dl.dropboxusercontent.com/u/30657009/ly/api.ly.bz2 | psql ly -f -

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
