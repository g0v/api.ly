require! <[optimist pgrest]>

export function plx(opts={+client}, cb)
  conString = optimist.argv.db ? process.env.PGDATABASE
  conString = "localhost/#conString" unless conString is // / //
  conString = "tcp://#conString"     unless conString is // :/ //

  pgrest .new conString, opts, cb

export function shellrun(cmd, opts, cb)
  require! shelljs
  c = shelljs.exec cmd, opts, cb
  c.stderr.on 'data' -> console.error it
