const { USER, DB } = process.env

require! <[async optimist path fs pgrest]>
{util}:ly = require \twlyparser

{_sitting_id} = require \./lib

{year, all, db=DB} = optimist.argv

[input] = optimist.argv._

ivod = JSON.parse fs.readFileSync input, \utf-8

plx <- pgrest.new db, {+client}

# by default, we only upsert entries within 7 days

unless all
  after = new Date( new Date! - 1000ms * 60s * 60min * 24hr * 7 )
  ivod.=filter ({time})->
    return new Date(time) > after

funcs = for {video_url_n}:x in ivod => let x, video_url_n
  (done) ->
    delete x.video_url_n
    [type, sitting]? = match x.summary
    | /公聽會/ => [\hearing, null]
    | /考察|視察|參訪|教育訓練/ => [\misc, null]
    | /第(\d+)次?(聯席|全體|全院)(委員)?會議?/ => [\sitting, +that.1]
    | /第(\d+)次會議?/ => [\sitting, +that.1]
    | /預備會議/ => [\sitting, 0]
    | /談話會/ => [\talk, null]
    | /臨時會/ => [\sitting]
    else
      console.log \unmatched x.summary, x.youtube_id
    if x.summary.match /會期(?:第.*?次臨時會)?(.*?)第([\d\s]+)次聯席/
      x.committee = try [util.parseCommittee c - /[兩三四五六七八]?委員會$/ for c in that.1?split /[,、，]/ when c]
      x.committee ?= try [util.parseCommittee c - /[兩三四五六七八]?委員會$/ for c in that.1?split /[,、，及]/ when c]
    else
      x.committee = if x.committee => [x.committee] else void
    #if type
    #  console.log x.youtube_id, type, _sitting_id x
    x.sitting_id = _sitting_id x
    #unless x.sitting_id
    #  console.log \wtf x
    return done! unless x.sitting_id
    x.type = type
    if x.first_frame_timestamp
      x.first_frame_timestamp = new Date that * 1000ms + 3600s * 8h * 1000ms
    #console.log x
    res <- plx.upsert collection: \ivod, q: {video_url_n}, $: $set: x, _, ->
      console.log \err, x
      throw itx
    done!

err, res <- async.series funcs
console.log \done err
plx.end!
