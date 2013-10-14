#!/usr/bin/env st-livescript
require! <[optimist pgrest async]>
{consume-events} = require \./lib/pgq
twly = require \./lib

{ queue="ldqueue", consumer="bill-details", dry, flush, dir} = optimist.argv

conString = optimist.argv.db ? process.env.PGDATABASE
conString = "localhost/#conString" unless conString is // / //
conString = "tcp://#conString"     unless conString is // :/ //

console.log "bill-details listening"

ly = require \twlyparser

plx <- pgrest .new conString, {+client}
batch, events, cb <- consume-events plx, {queue, consumer, table: 'public.bills', interval: 200ms, dry: dry ? flush}
return cb true unless events.length
funcs = for {ev_data, ev_type, ev_id} in events when ev_type is /I:bill_id/ and !ev_data.bill_ref
  let ev_data, ev_type, ev_id
    (done) ->
      err = ->
        console.log \err it?message
        plx.query "select pgq.event_retry($1, $2, $3::int)" [batch, ev_id, 3600], -> done!
      {bill_id} = ev_data
      console.log \=== bill_id
      info <- ly.misq.getBill bill_id, {dir}
      <- ly.misq.ensureBillDoc bill_id, info
      return done! unless info.doc.doc
      e, bill <- ly.misq.parse-bill-doc bill_id, {+lodev}
      return err e if e
      console.log \=== bill.reference if bill.reference
      res <- plx.upsert {
        collection: \bills
        q: {bill_id}
        $: $set: bill{abstract, docs, sponsors, cosponsors} <<< data: bill{related, content}, bill_ref: bill.reference
        }, _, -> err it
      console.log res
      return done!
return cb true unless funcs.length
console.log \start batch, \with funcs.length

err, res <- async.series funcs
cb true
