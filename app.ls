require! {optimist}
{argv} = optimist
conString = argv.db or process.env['PLV8XCONN'] or process.env['PLV8XDB'] or process.env.TESTDBNAME or process.argv?2
unless conString
  console.log "ERROR: Please set the PLV8XDB environment variable, or pass in a connection string as an argument"
  process.exit!
{pgsock} = argv

require! pgrest
plx <- pgrest .new conString, meta: do
  'pgrest.calendar': do
    f: {-raw}
    s: {date: -1}

{mount-default,with-prefix} = pgrest.routes!

process.exit 0 if argv.boot
{port=3000, prefix="/collections", host="127.0.0.1"} = argv
express = try require \express
throw "express required for starting server" unless express
app = express!

app.use express.json!

route = (path, fn) ->
  fullpath = "#{
      switch path.0
      | void => prefix
      | '/'  => ''
      | _    => "#prefix/"
    }#path"
  app.all fullpath, routes.route path, fn

<- plx.import-bundle \twly require.resolve \./package.json

twly = require \./lib
for name, f of twly
  if f.$plv8x
    plx.mk-user-func "#name#that" "twly:#name", ->

# XXX: make plv8x /sql define-schema reusable
<- plx.query """
DO $$
BEGIN
    IF NOT EXISTS(
        SELECT schema_name
          FROM information_schema.schemata
          WHERE schema_name = 'pgrest'
      )
    THEN
      EXECUTE 'CREATE SCHEMA pgrest';
    END IF;
END
$$;

CREATE OR REPLACE VIEW pgrest.calendar AS
  SELECT _calendar_session(calendar) as _session, * FROM public.calendar WHERE (calendar.ad IS NOT NULL);
"""

require cors! if argv.cors
cols <- mount-default plx, 'pgrest', with-prefix prefix, (path, r) ->
  args = [r]
  args.unshift cors! if argv.cors
  args.unshift path
  app.all ...args

app.listen port, host
console.log "Available collections:\n#{ cols.sort! * ' ' }"
console.log "Serving `#conString` on http://#host:#port#prefix"
