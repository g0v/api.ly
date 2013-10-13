#!/usr/bin/env st-livescript
require! <[optimist pgrest async]>
{consume-events} = require \./lib/pgq
twly = require \./lib

{ queue="ldqueue", consumer="ys-misq", dry, flush, dir="/tmp/misq"} = optimist.argv

throw "queue and consumer required" unless queue and consumer

conString = optimist.argv.db ? process.env.PGDATABASE
conString = "localhost/#conString" unless conString is // / //
conString = "tcp://#conString"     unless conString is // :/ //

console.log "ys-misq listening"

{misq} = require \twlyparser

plx <- pgrest .new conString, {+client}
batch, events, cb <- consume-events plx, {queue, consumer, table: 'public.sittings', interval: 200ms, dry: dry ? flush}
return cb true unless events.length
funcs = for {ev_data, ev_type, ev_id} in events when ev_type is 'I:id' and !ev_data.committee
  let ev_data, ev_type, ev_id
    (done) ->
      sitting_id = ev_data.id
      res <- misq.get ev_data, {dir, +agenda-only}
      funcs = for a in res.announcement => let a
        (done) ->
          res <- plx.upsert {
            collection: \bills
            q: {bill_id: a.id}
            $: $set: {a.summary, proposed_by: a.proposer}
            }, _, -> console.log \err it
          res <- plx.upsert {
            collection: \motions
            q: {sitting_id, bill_id: a.id}
            $: $set:
              motion_class: \announcement
              agenda_item: a.agendaItem
              subitem: a.subItem
            }, _, -> console.log \err it
          console.log a.id, res
          done!
      funcs ++= for d in res.discussion => let d
        (done) ->
          res <- plx.upsert {
            collection: \bills
            q: {bill_id: d.id}
            $: $set: {d.summary, proposed_by: d.proposer}
            }, _, -> console.log \err it
          res <- plx.upsert {
            collection: \motions
            q: {sitting_id, bill_id: d.id}
            $: $set:
              motion_class: \discussion
              agenda_item: d.agendaItem
              subitem: d.subItem
            }, _, -> console.log \err it
          console.log d.id, res
          done!
      err, res <- async.series funcs
      if err
        if err.data isnt /Status is a duplicate/
          console.log \== err
          return plx.query "select pgq.event_retry($1, $2, $3::int)" [batch, ev_id, 3], -> done!
      return done!
return cb true unless funcs.length

err, res <- async.series funcs
cb true
