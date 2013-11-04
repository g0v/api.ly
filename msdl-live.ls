{get-live-status} = require \twlyparser
require! fs

status <- get-live-status
for channel, {live,chbid} of status
  svdir = "/etc/sv/msdl-#channel"
  svc = "/etc/service/msdl-#channel"
  continue unless fs.existsSync svdir
  if live
    unless fs.existsSync svc
      fs.symlinkSync svdir, svc
      console.log "Started #channel"
  else
    if fs.existsSync svc
      fs.unlinkSync svc
      console.log "Stopped #channel"
