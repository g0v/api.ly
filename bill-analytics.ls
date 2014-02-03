require! <[googleapis moment pgrest optimist async xdg mkdirp path]>
const {DB, SERVICE_ACCOUNT, KEYFILE='analytics.pem'} = process.env
cachePath = xdg.basedir.cachePath "googleapis/discover"

err <- mkdirp path.dirname cachePath
throw err if err

{db=DB} = optimist.argv
plx <- pgrest.new db, {+client}

jwt = new googleapis.auth.JWT SERVICE_ACCOUNT, KEYFILE, null, ['https://www.googleapis.com/auth/analytics.readonly']

err, client <- googleapis.discover 'analytics', 'v3'
  .withOpts cache: path: cachePath
  .execute
err, result <- jwt.authorize

function get-ranks(from, to, cb)
  err, result <- client.analytics.data.ga.get do
    'ids': 'ga:78258693'
    'start-date': from
    'end-date': to
    'metrics': 'ga:visits,ga:newVisits'
    'dimensions': 'ga:pagePathLevel2'
    'sort': '-ga:visits'
    'filters': 'ga:pagePathLevel1==/bills/'
    'max-results': 25
  .with-auth-client jwt
  .execute
  if err
    console.log 'Error', err
    return cb null
  res = {}
  for [path, visits, newVisits] in result.rows
    path -= /^\//
    path -= /#.*$/
    path .= toUpperCase!
    res[path] ?= 0
    res[path] += +visits

  cb [[path, count] for path, count of res].sort -> (&1.1 - &0.1)



funcs = for days in [1, 7, 30] => let days
  (done) ->
    from = moment!subtract 'days', days .format 'YYYY-MM-DD'
    data <- get-ranks from, moment!format 'YYYY-MM-DD'
    #console.log days, data
    name = 'bill'
    timeframe = "#days"
    res <- plx.upsert collection: \stats.analytics, q: {name, timeframe}, $: $set: {content: JSON.stringify data}, _, -> throw it
    #console.log res
    done!

err, res <- async.series funcs
plx.end!
