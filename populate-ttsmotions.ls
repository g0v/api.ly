#!/usr/bin/env lsc
require! <[optimist pgrest async fscache]>
twly = require \./lib
cli = require \./lib/cli

{XRegExp} = require \xregexp

{dir="/tmp/misq",ad,session} = optimist.argv

cache = fscache.createSync 3600s * 1000ms * 24h * 3d, '/tmp/tts'

plx <- cli.plx {+client}

{util,misq} = require \twlyparser
{sprintf} = require \sprintf
require! shelljs

function get-sitting-id(name)
  res = twly._sitting_id util.get-sitting name
  res

function parse_roc_date(d)
  [_, y, m, d] = d.match /^(\d\d\d?)(\d\d)(\d\d)/
  [+y + 1911, +m , +d]

function parse_sitting(d)
  [_, ad, session, sitting, extra] = d.match /(\d+)屆(\d+)期(\d+)次(?:臨時會(\d+)會次)?/
  if extra
    "#ad#{session}T#{sitting}-#{extra}"
  else
    "#ad#{session}-#{sitting}"

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

function get-motions(_session, cb)
  key = "ttsmotions-#{_session}"
  if val = cache.getSync key
    return cb val
  code, output <- shellrun """
    casperjs scripts/tts.coffee --type=m --session=#{_session} --output=/dev/stdout | lsc node_modules/twlyparser/parse-tts.ls /dev/stdin
  """ {+silent}
  res = JSON.parse output
  cache.putSync key, res
  cb res

function _mapfields(entry)
  mapping =
    提案編號: \bill_refs
    系統號: \tts_id
    議案代碼: \tts_seq
    會議別: \sitting_type
    日期: \date
    主席: \chair
    資料來源: \source
    會議名稱: \sitting_name
    案別: \motion_type
    會議及提案內容: \summary
    決議: \resolution
    提案影像: \source
    主題: \topic
    類別: \category
    附加詞: \tags
    進度: \progress
    備註: \memo
    發言委員: \speakers
    委員會: \committee
    機關: \agencies

  entry = {[mapping[k], v] for k, v of entry when mapping[k]}
  [tts_id, tts_seq] = delete entry<[tts_id tts_seq]>
  entry.tts_key = [tts_id, tts_seq].join \:
  if entry.bill_refs
    entry.bill_refs .= map -> it.replace /政/ \G .replace /委/ \L
  entry.date = parse_roc_date entry.date .join \-
  if entry.source
    entry.source = parse_source entry.source
  if entry.speakers
    entry.speakers .= filter -> it
    .map ->
      entry = """\\s+
          (?<pages> [\\d\\-]+)\\s+
          (?<link> \\[.*?\\]),?
      """
      res = XRegExp.exec it, XRegExp """
        ^(?<name> .*?)
        \\s+
        (?:\\((?<n> \\d+)次\\))?
        \\s+ p\\.
        (?<all>(
          #entry
        )+$)
      """, \xn
      links = []
      console.log it, res unless res?all
      return unless res
      while res.all = XRegExp.replace res.all, XRegExp(entry, \x), (->
        #links.push it{pages} <<< link:
        links.push JSON.parse it.link
        return '')
        1
      res{name,n} <<< {links}
    .filter -> it

  # XXX just verify with entry.sitting_id
  delete entry.committee

  entry.sitting_id = get-sitting-id entry.sitting_name - /\s/g - /\(勘誤\)$/
  console.error entry.sitting_name unless entry.sitting_id

  entry


_session = sprintf '%02d%02d', +ad, +session
res <- get-motions _session

funcs = for entry in res.0 => let entry = _mapfields entry
  (done) ->
    q = entry{tts_key}
    data = entry
    data.bill_refs ?= null
    delete data.tts_key
    res <- plx.upsert {
      collection: \ttsmotions
      q: q
      $: $set: data
    }, _, -> console.log \err it
    return done!

console.log \upserintg funcs.length

err, res <- async.series funcs

console.log \done
plx.end!
