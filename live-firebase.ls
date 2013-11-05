{get-live-status} = require \twlyparser
require! \firebase

{FIREBASE, FIREBASE_SECRET} = process.env
root = new firebase FIREBASE

err <- root.auth FIREBASE_SECRET
throw err if err

doit = ->
  status <- get-live-status

  err <- root.child "status" .set {channels: status, updated: new Date!getTime!}

  set-timeout doit, 300s * 1000ms

doit!
