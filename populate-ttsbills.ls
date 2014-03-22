#!/usr/bin/env lsc
require! <[optimist async fscache]>
twly = require \./lib

require! \./lib/cli

{dir="/tmp/misq",ad,session} = optimist.argv

cache = fscache.createSync 3600s * 1000ms * 24h * 3d, '/tmp/tts'

{sprintf} = require \sprintf
require! shelljs

{parse_roc_date,parse_source} = twly

function parse_sitting(d)
  [_, ad, session, sitting, extra] = d.match /(\d+)屆(\d+)期(\d+)次(?:臨時會(\d+)會次)?/
  if extra
    "#{ad}-#{session}T#{sitting}-YS-#{extra}"
  else
    "#{ad}-#{session}-YS-#{sitting}"


function get-bills(_session, cb)
  key = "ttsbills-#{_session}"
  if val = cache.getSync key
    return cb val
  code, output <- cli.shellrun """
    casperjs scripts/tts.coffee --type=b --session=#{_session} --output=/dev/stdout | lsc node_modules/twlyparser/parse-tts.ls --bill=1 /dev/stdin
  """ {+silent}
  res = JSON.parse output
  cache.putSync key, res
  cb res

function _mapfields(entry)
  mapping =
    系統號: \tts_id
    提案編號: \bill_ref
    法名稱: \law_name
    法編號: \law_id
    提案影像: \source
    會期: \sitting_introduced
    提案日期: \introduced
    "提案委員/機關": \sponsors

  entry = {[mapping[k], v] for k, v of entry when mapping[k]}
  entry.bill_ref = entry.bill_ref.replace /政/ \G .replace /委/ \L
  entry.introduced = parse_roc_date entry.introduced .join \-
  if entry.source
    entry.source = parse_source entry.source

  entry.cosponsors = entry.sponsors?連署提案
  entry.sponsors = entry.sponsors?主提案
  entry.sitting_introduced = parse_sitting entry.sitting_introduced

  entry

plx <- cli.plx {+client}

res <- get-bills sprintf '%02d%02d', +ad, +session

funcs = []

for entry in res.0 => let entry = _mapfields entry
  if entry.law_id
    funcs.push (done) ->
      res <- plx.upsert {
        collection: \laws
        q: id: entry.law_id
        $: $set: name: entry.law_name ? 'NA'
      }, _, -> console.log \err it, \laws, entry
      return done!
    funcs.push (done) ->
      res <- plx.upsert {
        collection: \amendments
        q: entry{bill_ref,law_id}
        $: $set: entry{json,tts_id,source}
      }, _, -> console.log \err it, \amendments, entry
      return done!
  else
    console.error "no law_id", entry.bill_ref


  funcs.push (done) ->
    res <- plx.upsert {
      collection: \ttsbills
      q: entry{bill_ref}
      $: $set: entry{sponsors,cosponsors,introduced,sitting_introduced}
    }, _, -> console.log \err it, \ttsbills, entry
    return done!

console.log \upserintg funcs.length

err, res <- async.series funcs

console.log \done
plx.end!
