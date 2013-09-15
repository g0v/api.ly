{ sprintf } = require \sprintf

export function bootstrap(plx, cb)
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

  cb!


export function _calendar_session({ad,session,extra})
  _session = if extra
    sprintf "%02dT%02d", session, extra
  else
    sprintf "%02d", session
  sprintf "%02d-%s", ad, _session

_calendar_session.$plv8x = '(calendar):text'
