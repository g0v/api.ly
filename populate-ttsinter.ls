#!/usr/bin/env lsc
require! <[optimist async fscache]>
twly = require \./lib

require! \./lib/cli

{dir="/tmp/misq",ad,session} = optimist.argv

cache = fscache.createSync 3600s * 1000ms * 24h * 3d, '/tmp/tts'

{sprintf} = require \sprintf
require! shelljs

{parse_roc_date,parse_source} = twly

function get-inter(_session, cb)
  key = "ttsbills-#{_session}"
  if val = cache.getSync key
    return cb val
  code, output <- cli.shellrun """
    casperjs scripts/tts.coffee --type=i --session=#{_session} --output=/dev/stdout | lsc node_modules/twlyparser/parse-tts.ls /dev/stdin
  """ {+silent}
  res = JSON.parse output
  cache.putSync key, res
  cb res

function _mapfields(entry)
  mapping =
    系統號: \tts_id
    專案編號: \wrans_id
    質詢人: \asked_by
    質詢日期: \date_asked
    質詢公報: \source
    案由: \summary
    答復否: \answered,
    答復日期: \date_answered,
    答復公報: \answer_source
    答復人: \answered_by
    主題: \topic
    類別: \category
    關鍵詞: \keywords
    質詢性質: \interpellation_type

  entry = {[mapping[k] ? k, v] for k, v of entry when mapping[k]}
  entry.date_asked = parse_roc_date entry.date_asked .join \-
  entry.answered = entry.answered is '已答'
  if entry.source
    entry.source = parse_source entry.source

  if entry.date_answered
    entry.answers = for i in [0 to entry.date_answered.length-1]
      do
        date: parse_roc_date entry.date_answered[i] .join \-
        source: parse_source entry.answer_source[i]
    delete entry.date_answered
    delete entry.answer_source

  entry

plx <- cli.plx {+client}

res <- get-inter sprintf '%02d%02d', +ad, +session

funcs = []

for entry in res.0 => let entry = _mapfields entry
  data = entry
  tts_id = delete data.tts_id
  funcs.push (done) ->
    res <- plx.upsert {
      collection: \ttsinterpellation
      q: {tts_id}
      $: $set: data
    }, _, -> console.log \err it, tts_id, entry
    return done!

console.log \upserintg funcs.length

err, res <- async.series funcs

console.log \done
plx.end!
