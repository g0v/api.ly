{ sprintf } = require \sprintf

export function bootstrap(plx, cb)
  <- plx.query """
  CREATE OR REPLACE function is_valid_time(text) RETURNS boolean language plpgsql immutable as $$
  BEGIN
    RETURN CASE WHEN $1::time is null THEN false else true END;
  EXCEPTION WHEN OTHERS THEN
    return false;
  END;$$;

  CREATE TABLE IF NOT EXISTS calendar (
      id integer PRIMARY KEY,
      date date,
      time_start time default '00:00',
      time_end time default '23:59',
      type text,
      name text,
      chair text,
      summary text,
      committee text[],
      ad integer,
      session integer,
      extra integer,
      sitting integer,
      raw json
  );

  CREATE TABLE IF NOT EXISTS sittings (
      id text PRIMARY KEY,
      name text,
      summary text,
      committee text[],
      ad integer,
      session integer,
      extra integer,
      sitting integer
  );
  """

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

  """
  require! pgrest
  <- pgrest.bootstrap plx, \twly require.resolve \../package.json

  <- plx.query """
  CREATE INDEX calendar_sitting on calendar (_calendar_sitting_id(calendar));

  CREATE OR REPLACE VIEW pgrest.sittings AS
    SELECT *, (SELECT COALESCE(ARRAY_TO_JSON(ARRAY_AGG(_)), '[]') FROM (SELECT calendar.id as calendar_id, chair, date, time_start, time_end from pgrest.calendar where sitting_id = sittings.id order by calendar.id) as _) as dates FROM public.sittings;
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
_calendar_sitting_id.$bootstrap = true
