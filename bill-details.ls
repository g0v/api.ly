#!/usr/bin/env st-livescript
require! <[optimist pgrest async]>
{consume-events} = require \./lib/pgq
twly = require \./lib

{ queue="ldqueue", consumer="bill-details", dry, flush, dir, force} = optimist.argv

conString = optimist.argv.db ? process.env.PGDATABASE
conString = "localhost/#conString" unless conString is // / //
conString = "tcp://#conString"     unless conString is // :/ //

ly = require \twlyparser

plx <- pgrest .new conString, {+client}

function update-bill(bill_id, cb, err)
  info <- ly.misq.getBill bill_id, {dir}
  return err new Error \getbill unless info?doc

  e <- ly.misq.ensureBillDoc bill_id, info
  return err e if e
  return cb! unless info.doc.doc

  e, bill <- ly.misq.parse-bill-doc bill_id, {+lodev}
  return err e, bill if e

  plx.upsert {
    collection: \bills
    q: {bill_id}
    $: $set: bill{bill_ref, abstract, doc, sponsors, cosponsors} <<< data: bill{related, content}
  }, cb, -> err it, bill

if force
  rows <- plx.query "select bill_id from bills where abstract is null"
  funcs = for {bill_id}, i in rows => let bill_id, i
    (done) ->
      <- update-bill bill_id, _, (e, bill) ->
        if e?message is /duplicate key/
          dup <- plx.select collection: \bills, fo: 1, q: {bill.bill_ref}
          if bill.bill_ref isnt /-/
            <- update-bill dup.bill_id, _
            console.log \updated dup.bill_id, it

          return done null, bill_id, \dup, dup.bill_id, bill.bill_ref
        else
          return done null, bill_id, \error e
      done null, bill_id, it ? {+nodoc}

  err, res <- async.series funcs
  console.log res
  console.log err if err
  process.exit 0

return if force

console.log "bill-details listening"
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
      res <- update-bill bill_id, _, err

      console.log res
      return done!
return cb true unless funcs.length
console.log \start batch, \with funcs.length

err, res <- async.series funcs
cb true
