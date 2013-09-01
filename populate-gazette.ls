const { USER, DB } = process.env

require! <[async optimist path fs pgrest]>
{util}:ly = require \twlyparser

{year, force, all, db=DB} = optimist.argv

plx <- pgrest.new db, {}

check-gazette-table = (cb) ->
    table = \gazette
    err, {rows: entries}? <- plx.conn.query "SELECT * FROM pg_tables WHERE schemaname='public' AND tablename='#table'"
    if !entries.length then do ->
        console.log "gazette table does not exist, create it"
        <- plx.conn.query "
        CREATE TABLE #table
         (id INTEGER PRIMARY KEY,
         year TEXT,
         vol TEXT,
         date TIMESTAMP,
         ad INTEGER,
         session INTEGER,
         sitting INTEGER,
         secret INTEGER,
         extra INTEGER)"
        cb!
    else
        cb!

<- check-gazette-table

update-gazette-list = (cb) ->
    err, {rows:[{max:seen}]} <- plx.conn.query "SELECT max(id) FROM gazette"
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

<- update-gazette-list

console.log "upserted entries from twlyparser.gazette to postgresql"

check-index-table = (cb) ->
    table = \gazette_index
    err, {rows: entries}? <- plx.conn.query "SELECT * FROM pg_tables WHERE schemaname='public' AND tablename='#table'"
    if !entries.length then do ->
        console.log "index table does not exist, create it"
        <- plx.conn.query "
        CREATE TABLE #table
         (gazette INTEGER REFERENCES gazette(id),
         book TEXT,
         seq TEXT,
         type TEXT,
         summary TEXT,
         files TEXT[],
         ad INTEGER,
         session INTEGER ,
         sitting INTEGER ,
         extra INTEGER ,
         committee TEXT[],
         PRIMARY KEY (gazette, book, seq, type))"
        cb!
    else
        cb!

<- check-index-table

update-index-list = (cb) ->
    err, {rows:[{max:seen}]} <- plx.conn.query "SELECT max(gazette) FROM gazette_index"
    throw err if err

    funcs = []
    for i in ly.index => let i
        if +i.gazette > seen
            funcs.push (done) ->
                console.log \upserting: +i.gazette
                res <- plx.upsert collection: \gazette_index q:{gazette: +i.gazette, i.book, i.seq, i.type}, $: $set: {i.summary, i.files, i.ad, i.session, i.sitting, i.extra, i.committee}, _, -> throw it
                done!

    console.log \to \upsert: funcs.length
    err, res <- async.series funcs
    cb!

<- update-index-list

console.log "upserted entries from twlyparser.index to postgresql"

plx.end!

