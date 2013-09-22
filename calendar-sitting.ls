#!/usr/bin/env st-livescript
require! <[optimist pgrest async]>
{consume-events} = require \./lib/pgq
twly = require \./lib

{ queue="ldqueue", consumer="calendar-sitting", init} = optimist.argv

conString = optimist.argv.db ? process.env.PGDATABASE
conString = "localhost/#conString" unless conString is // / //
conString = "tcp://#conString"     unless conString is // :/ //


plx <- pgrest .new conString, {+client}

function populate-sitting(id, cb)
  [res]? <- plx.query "select * from pgrest.calendar where id = $1" [id]
  console.log \checking id, res.sitting_id
  res <- plx.upsert {collection: \sittings, q: {id: res.sitting_id}, $: $set: res{ad,session,sitting,extra,name,summary,committee}}, _,  -> console.log \err it
  cb!

if init => return do ->
  res <- plx.query """
    select id from (select id, sitting_id, (select count(*) from sittings where sittings.id = sitting_id) cnt from pgrest.calendar where type = 'sitting' order by id) _ where cnt = 0;
  """

  funcs = for {id} in res => let id
    (done) ->
      populate-sitting id, done
  console.log \populating funcs.length
  err, res <- async.series funcs
  process.exit 0


batch, events, cb <- consume-events plx, {queue, consumer, table: 'public.calendar', interval: 200ms}

console.log events
return cb true unless events.length

funcs = for {ev_data, ev_type, ev_id} in events when ev_type is /[UI]:id/ and ev_data.ad and ev_data.type is \sitting => let ev_data
  (done) ->
    populate-sitting ev_data.id, done
return cb true unless funcs.length

err, res <- async.series funcs
cb true
