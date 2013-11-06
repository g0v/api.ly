ffmpeg = require 'fluent-ffmpeg'
require! optimist
require! \firebase
Q = require \q

{output = 'output.png'} = optimist.argv

root = new firebase "https://iv0d.firebaseio.com"

doit = ->
  <- root.child 'status/channels' .once \value
  console.log it.val!

  status = it.val!

  snapshots = []
  for channel, {live} of status when live => let channel
    deferred = Q.defer!
    snapshots.push deferred.promise
    proc = new ffmpeg source: "http://ivod.ly.g0v.tw/videos/#channel.webm"
    .addOption '-vframes', 1
    .addOption '-r', 1
    .saveToFile "/tmp/#channel.jpg" (stdout, stderr) ->
      console.log "got #channel"
      deferred.resolve!



  <- Q.all snapshots .then
  console.log \alldone

  shell = require 'shelljs'
  channels = <[SWE TRA JUD
              FND YS  IAD
              EDU ECO FIN
              PRO CON DIS]>
  files = channels.map -> if status[it].live => "/tmp/#it.jpg" else "empty.png"
  code, output <- shell.exec "montage #{files.join ' '} -geometry 160x128+0+0 -tile 3x4 #output"
  setTimeout doit, 60s * 1000ms

doit!
