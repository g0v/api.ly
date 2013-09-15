{ sprintf } = require \sprintf

export function bootstrap(plx, cb)
  next <- plx.import-bundle-funcs \twly require.resolve \../package.json
  <- next
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

  CREATE INDEX calendar_sitting on calendar (_calendar_sitting_id(calendar));

  CREATE OR REPLACE VIEW pgrest.calendar AS
    SELECT _calendar_sitting_id(calendar) as sitting_id, * FROM public.calendar WHERE (calendar.ad IS NOT NULL);
  """

  cb!


export function _calendar_session({ad,session,extra})
  return unless ad
  _session = if extra
    sprintf "%02dT%02d", session, extra
  else
    sprintf "%02d", session
  sprintf "%02d-%s", ad, _session

_calendar_session.$plv8x = '(calendar):text'

export function _calendar_sitting_id({type,committee,sitting}:calendar)
  return unless type is \sitting
  session = _calendar_session calendar
  return unless session
  sitting_type = if committee => committee.join '-' else 'YS'
  [session, sitting_type, sprintf "%02d" sitting].join \-

_calendar_sitting_id.$plv8x = '(calendar):text'
