#!/usr/bin/env st-livescript
require! <[optimist pgrest async moment]>
{consume-events} = require \./lib/pgq
twly = require \./lib

conString = optimist.argv.db ? process.env.PGDATABASE
conString = "localhost/#conString" unless conString is // / //
conString = "tcp://#conString"     unless conString is // :/ //

{dir="/tmp/misq"} = optimist.argv
{misq} = require \twlyparser

plx <- pgrest .new conString, {+client}
sittings <- plx.query "select * from pgrest.sittings where ad = 8 and committee is null and proceeding_url is null order by id desc limit 10"

funcs = for {dates}:s in sittings => let s, dates
  (done) ->
    sitting_id = twly._sitting_id s
    unless dates?0?date
      console.log \wtf sitting_id, dates
      return done!
    return done! if moment!subtract('days', 7) < moment dates.0.date
    [y, m, d] = dates.0.date.split \-

    res <- misq.getMeetingAgenda {meetingTime: "#{y - 1911}/#m/#d", departmentCode: '0703'}
    return done! unless proceeding_url = res.議事錄
    console.log res.會議名稱

    console.log \processing s.id
    res <- misq.get s, {dir}
    console.log sitting_id

    funcs = for a in res.announcement => let a
      (done) ->
        return done! unless a.item
        res <- plx.select {
          collection: \motions
          q: {bill_id: a.id, sitting_id}
          +fo
        }, _, ->
          console.log \err a.id
          res <- plx.upsert {
            collection: \motions
            q: {sitting_id, bill_id: a.id}
            $: $set: a{item,resolution,status,committee} <<< motion_class: \announcement
          }, _, -> console.log \moreerr it, sitting_id, a.id, a
          return done!
        res <- plx.upsert {
          collection: \motions
          q: {sitting_id, bill_id: a.id}
          $: $set: a{item,resolution,status,committee}
        }, _, -> console.log \err it
        console.log a unless a.id
        console.log a.id, res
        done!
    funcs ++= for d in res.discussion when d.dtype isnt \exmotion and d.type isnt \exmotion => let d
      (done) ->
        console.log d
        return done!
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
    plx.upsert
    res <- plx.upsert {
      collection: \sittings
      q: {id: sitting_id}
      $: $set: {proceeding_url}
    }, _, -> console.log \err it
    res.議事錄
    done!


err, res <- async.series funcs

plx.end!
