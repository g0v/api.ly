#!/usr/bin/env lsc
require! <[optimist pgrest async fscache]>
twly = require \./lib

{XRegExp} = require \xregexp

{dir="/tmp/misq",ad,session} = optimist.argv

conString = optimist.argv.db ? process.env.PGDATABASE
conString = "localhost/#conString" unless conString is // / //
conString = "tcp://#conString"     unless conString is // :/ //

cache = fscache.createSync 3600s * 1000ms * 24h * 3d, '/tmp/tts'

{util,misq} = require \twlyparser
{sprintf} = require \sprintf
require! shelljs

function parse_roc_date(d)
  [_, y, m, d] = d.match /^(\d\d\d?)(\d\d)(\d\d)/
  [+y + 1911, +m , +d]

function parse_sitting(d)
  [_, ad, session, sitting, extra] = d.match /(\d+)屆(\d+)期(\d+)次(?:臨時會(\d+)會次)?/
  if extra
    "#{ad}-#{session}T#{sitting}-YS-#{extra}"
  else
    "#{ad}-#{session}-YS-#{sitting}"

function parse_source(d)
  a = d.split /(?:[\s,;]*)?(.*?)\s*(\[.*?\])/
  res = []

  do
    [_, text, link]:x = a.slice 0, 3
    if x.length is 3
      res.push {text, link: JSON.parse link}
    else
      break
  while a.splice 0, 3

  res

function shellrun(cmd, opts, cb)
  c = shelljs.exec cmd, opts, cb
  c.stderr.on 'data' -> console.error it

function get-bills(_session, cb)
  key = "ttsbills-#{_session}"
  if val = cache.getSync key
    return cb val
  code, output <- shellrun """
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

  entry.cosponsors = entry.sponsors.連署提案
  entry.sponsors = entry.sponsors.主提案
  entry.sitting_introduced = parse_sitting entry.sitting_introduced

  entry

plx <- pgrest .new conString, {+client}

_session = sprintf '%02d%02d', +ad, +session
res <- get-bills _session

funcs = []

for entry in res.0 => let entry = _mapfields entry
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
      $: $set: entry{law_name,json,tts_id,source}
    }, _, -> console.log \err it, \amendments, entry
    return done!

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
