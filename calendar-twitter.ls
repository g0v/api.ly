#!/usr/bin/env st-livescript
require! <[optimist pgrest async]>
{consume-events} = require \./lib/pgq
twly = require \./lib

{ queue="ldqueue", consumer="twitter", dry, flush} = optimist.argv

throw "queue and consumer required" unless queue and consumer

conString = optimist.argv.db ? process.env.PGDATABASE
conString = "localhost/#conString" unless conString is // / //
conString = "tcp://#conString"     unless conString is // :/ //

function twitter-status(res)
  sitting_type = if res.committee is null => "院會" else res.committee.map(-> util.committees[it]).join '/'

  # preserve 25 chars for url
  status = "[會議預報 - #{res.raw.date}] #{twly._calendar_session(res)}#sitting_type\##{res.sitting} #{res.summary}"
  if status.length >= 115
    status .= substr(0, 114) + '…'

  url = "http://www.ly.gov.tw/01_lyinfo/0109_meeting/meetingView.action?id=#{res.id}"

  "#status #url"

config = require \./twitter.json
{util} = require \twlyparser
twitterAPI = require 'node-twitter-api'
twitter = new twitterAPI config{consumerKey, consumerSecret} <<< callback: 'http://ly.g0v.tw/callback'

plx <- pgrest .new conString, {+client}
batch, events, cb <- consume-events plx, {queue, consumer, table: 'public.calendar', interval: 200ms, dry: dry ? flush}
return cb true unless events.length
funcs = for {ev_data, ev_type, ev_id} in events when ev_type is /[UI]:id/ and ev_data.ad and ev_data.type is \sitting => let ev_data, ev_type, ev_id
  console.log ev_type, ev_data.id
  (done) ->
    [res]? <- plx.query "select * from pgrest.calendar where id = $1" [ev_data.id]
    if dry or flush
      console.log \sending twitter-status res
      if dry
        process.exit 0
      done!
    err, data, response <- twitter.statuses "update", {status: twitter-status res}, config.accessToken, config.accessTokenSecret
    <- setTimeout _, 1000ms
    if err
      if err.data isnt /Status is a duplicate/
        console.log \== err
        return plx.query "select pgq.event_retry($1, $2, $3::int)" [batch, ev_id, 3], -> done!
    return done!
return cb true unless funcs.length

err, res <- async.series funcs
cb true
