const { USER, DB } = process.env

require! <[async optimist path fs pgrest]>
{util}:ly = require \twlyparser

{year, force, all, db=DB} = optimist.argv

plx <- pgrest.new db, {}

check-gazette-table = (cb) ->
    table = \gazette
    err, {rows: entries}? <- plx.conn.query "select * from pg_tables where schemaname='public' and tablename='#table'"
    if !entries.length then do ->
        console.log "table not exist, create it"
        <- plx.conn.query "
        create table #table
         (id integer primary key,
         year text,
         vol text,
         date timestamp,
         ad integer,
         session integer,
         sitting integer,
         secret integer,
         extra integer)"
        cb!
    else
        cb!

<- check-gazette-table

update-list = (cb) ->
    err, {rows:[{max:seen}]} <- plx.conn.query "select max(id) from gazette"
    throw err if err

    funcs = []
    for k, v of ly.gazettes => let k, v
        if +k > seen
            funcs.push (done) ->
                console.log \upserting: +k
                res <- plx.upsert collection: \gazette q:{id: +k}, $: $set: {v.year, v.vol, v.date, v.ad, v.session, v.sitting, v.secret, v.extra}, _, -> throw it
                done!

    console.log \to \upsert: funcs.length
    err, res <- async.series funcs
    cb!

<- update-list

console.log "upserted entries from twlyparser.gazette to postgresql"

plx.end!

